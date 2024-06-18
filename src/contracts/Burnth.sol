// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./utils/MptMiddleVerifier.sol";
import "./utils/MptLastVerifier.sol";
import "./utils/SpendVerifier.sol";

contract Burnth is ERC20 {
    uint256 constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct Groth16Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    struct PrivateProofOfBurn {
        uint256 blockNumber;
        uint256 coin;
        uint256 nullifier;
        uint256[] layers;
        Groth16Proof rootProof;
        Groth16Proof[] midProofs;
        Groth16Proof lastProof;
        bool isEncrypted;
        address target;
        bytes header_prefix;
        bytes32 state_root;
        bytes header_postfix;
    }

    SpendVerifier spend_verifier = new SpendVerifier();
    MptLastVerifier mpt_last_verifier = new MptLastVerifier();
    MptMiddleVerifier mpt_middle_verifier = new MptMiddleVerifier();
    mapping(uint256 => bool) public nullifiers;
    mapping(uint256 => bool) public coins;

    event CoinGenerated(address recipient, uint256 coin);
    event CoinSpent(
        address spender,
        uint256 coin,
        uint256 remainingCoin,
        uint256 withdrawnBalance,
        address destination
    );

    constructor() ERC20("Burnth", "BURNTH") {}

    /**
     * @notice Verifies the validity of a provided private proof of burn.
     *
     * @dev This function checks the following:
     * - The length of the header prefix must be exactly 91 bytes.
     * - The nullifier must not have been used before (to prevent double spending).
     * - The combined hash of the header prefix, state root, and header postfix must match the block hash of the given block number.
     * - The root proof and all intermediate Merkle proofs must be valid.
     * - The last proof in the Merkle tree must be valid and correctly represent the encrypted state if applicable.
     *
     * @param proof The private proof of burn containing all necessary cryptographic proofs and metadata.
     */
    function verify_proof(PrivateProofOfBurn calldata proof) internal {
        require(
            proof.header_prefix.length == 91,
            "Burnth: invalid header prefix length"
        );

        require(!nullifiers[proof.nullifier], "Burnth: nullifier already used");
        nullifiers[proof.nullifier] = true;

        require(
            keccak256(
                abi.encodePacked(
                    proof.header_prefix,
                    proof.state_root,
                    proof.header_postfix
                )
            ) == blockhash(proof.blockNumber),
            "Burnth: invalid block hash"
        );

        require(
            mpt_middle_verifier.verifyProof(
                proof.rootProof.a,
                proof.rootProof.b,
                proof.rootProof.c,
                [
                    uint256(bytes32(proof.state_root)) % FIELD_SIZE,
                    proof.layers[proof.layers.length - 1]
                ]
            ),
            "MptRootVerifier: invalid proof"
        );

        uint256 layersLength = proof.layers.length - 1;

        for (uint256 i = 0; i < layersLength; i++) {
            require(
                mpt_middle_verifier.verifyProof(
                    proof.midProofs[i].a,
                    proof.midProofs[i].b,
                    proof.midProofs[i].c,
                    [proof.layers[i + 1], proof.layers[i]]
                ),
                "MptMiddleVerifier: invalid proof"
            );
        }

        require(
            mpt_last_verifier.verifyProof(
                proof.lastProof.a,
                proof.lastProof.b,
                proof.lastProof.c,
                [
                    proof.layers[0],
                    proof.coin,
                    proof.nullifier,
                    proof.isEncrypted ? 1 : 0
                ]
            ),
            "MptLastVerifier: invalid proof"
        );
    }

    /**
     * @notice Mints new tokens based on a private proof of burn.
     *
     * @dev This function first verifies the provided proof using `verify_proof`.
     * If the proof indicates the coin is encrypted, it marks the coin as valid and emits a `CoinGenerated` event.
     * Otherwise, it mints the token directly to the target address.
     *
     * @param proof The private proof of burn containing all necessary cryptographic proofs and metadata.
     */
    function mint(PrivateProofOfBurn calldata proof) external {
        verify_proof(proof);

        if (proof.isEncrypted) {
            coins[proof.coin] = true;
            emit CoinGenerated(proof.target, proof.coin);
        } else {
            _mint(proof.target, proof.coin);
        }
    }

    /**
     * @notice Spends a valid coin and mints new tokens to the specified destination address.
     *
     * @dev This function:
     * - Checks if the coin is valid.
     * - Invalidates the spent coin.
     * - Verifies the spend proof.
     * - Marks the remaining coin as valid.
     * - Mints the withdrawn balance to the destination address.
     * - Emits `CoinSpent` and `CoinGenerated` events.
     *
     * @param coin The coin to be spent.
     * @param remainingCoin The remaining balance after spending the coin.
     * @param withdrawnBalance The balance to be withdrawn and minted to the destination address.
     * @param destination The address to which the withdrawn balance will be minted.
     * @param proof The Groth16 proof verifying the spend operation.
     */
    function spend(
        uint256 coin,
        uint256 remainingCoin,
        uint256 withdrawnBalance,
        address destination,
        Groth16Proof calldata proof
    ) external {
        require(coins[coin], "Burnth: coin is not valid");
        coins[coin] = false;

        require(
            spend_verifier.verifyProof(
                proof.a,
                proof.b,
                proof.c,
                [coin, remainingCoin, withdrawnBalance]
            ),
            "SpendVerifier: invalid proof"
        );

        coins[remainingCoin] = true;
        _mint(destination, withdrawnBalance);

        emit CoinSpent(
            msg.sender,
            coin,
            remainingCoin,
            withdrawnBalance,
            destination
        );
        emit CoinGenerated(destination, remainingCoin);
    }
}
