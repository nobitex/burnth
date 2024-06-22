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
     * @param _proof The private proof of burn containing all necessary cryptographic proofs and metadata.
     */
    function verify_proof(PrivateProofOfBurn calldata _proof) internal {
        require(
            _proof.header_prefix.length == 91,
            "Burnth: invalid header prefix length"
        );

        require(
            !nullifiers[_proof.nullifier],
            "Burnth: nullifier already used"
        );
        nullifiers[_proof.nullifier] = true;

        require(
            keccak256(
                abi.encodePacked(
                    _proof.header_prefix,
                    _proof.state_root,
                    _proof.header_postfix
                )
            ) == blockhash(_proof.blockNumber),
            "Burnth: invalid block hash"
        );

        require(
            mpt_middle_verifier.verifyProof(
                _proof.rootProof.a,
                _proof.rootProof.b,
                _proof.rootProof.c,
                [
                    uint256(bytes32(_proof.state_root)) % FIELD_SIZE,
                    _proof.layers[_proof.layers.length - 1]
                ]
            ),
            "MptRootVerifier: invalid proof"
        );

        uint256 layersLength = _proof.layers.length - 1;

        for (uint256 i = 0; i < layersLength; i++) {
            require(
                mpt_middle_verifier.verifyProof(
                    _proof.midProofs[i].a,
                    _proof.midProofs[i].b,
                    _proof.midProofs[i].c,
                    [_proof.layers[i + 1], _proof.layers[i]]
                ),
                "MptMiddleVerifier: invalid proof"
            );
        }

        require(
            mpt_last_verifier.verifyProof(
                _proof.lastProof.a,
                _proof.lastProof.b,
                _proof.lastProof.c,
                [
                    _proof.layers[0],
                    _proof.coin,
                    _proof.nullifier,
                    _proof.isEncrypted ? 1 : 0
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
     * @param _proof The private proof of burn containing all necessary cryptographic proofs and metadata.
     */
    function mint(PrivateProofOfBurn calldata _proof) external {
        verify_proof(_proof);

        if (_proof.isEncrypted) {
            coins[_proof.coin] = true;
            emit CoinGenerated(_proof.target, _proof.coin);
        } else {
            _mint(_proof.target, _proof.coin);
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
     * @param _coin The coin to be spent.
     * @param _remainingCoin The remaining balance after spending the coin.
     * @param _withdrawnBalance The balance to be withdrawn and minted to the destination address.
     * @param _destination The address to which the withdrawn balance will be minted.
     * @param _proof The Groth16 proof verifying the spend operation.
     */
    function spend(
        uint256 _coin,
        uint256 _remainingCoin,
        uint256 _withdrawnBalance,
        address _destination,
        Groth16Proof calldata _proof
    ) external {
        require(coins[_coin], "Burnth: coin is not valid");
        coins[_coin] = false;

        require(
            spend_verifier.verifyProof(
                _proof.a,
                _proof.b,
                _proof.c,
                [_coin, _remainingCoin, _withdrawnBalance]
            ),
            "SpendVerifier: invalid proof"
        );

        coins[_remainingCoin] = true;
        _mint(_destination, _withdrawnBalance);

        emit CoinSpent(
            msg.sender,
            _coin,
            _remainingCoin,
            _withdrawnBalance,
            _destination
        );
        emit CoinGenerated(_destination, _remainingCoin);
    }
}
