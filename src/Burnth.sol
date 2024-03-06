// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./MptMiddleVerifier.sol";
import "./MptLastVerifier.sol";
import "./SpendVerifier.sol";
import "./Console.sol";

contract Burnth is ERC20 {
    uint256 constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct Groth16Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    struct PrivateProofOfBurn {
        uint256 blockNumber;
        uint256 coin;
        uint256 nullifier;
        Groth16Proof rootProof;
        Groth16Proof lastProof;
        bool isEncrypted;
        address target;
        bytes32 state_root;
        uint256[] layers; 
        Groth16Proof[] midProofs; 
        bytes header_prefix; 
        bytes header_postfix; 
    }

    SpendVerifier spend_verifier = new SpendVerifier();
    MptLastVerifier mpt_last_verifier = new MptLastVerifier();
    MptMiddleVerifier mpt_middle_verifier = new MptMiddleVerifier();
    mapping(uint256 => bool) public nullifiers;
    mapping(uint256 => bool) public coins;

    event CoinGenerated(address recipient, uint256 coin);
    event CoinSpent(
        address spender, uint256 coin, uint256 remainingCoin, uint256 withdrawnBalance, address destination
    );

    constructor() ERC20("Burnth", "BURNTH") {}

    function verify_proof(PrivateProofOfBurn calldata proof) internal {
        uint256 is_encrypted = proof.isEncrypted ? 1 : 0;

        require(proof.header_prefix.length == 91, "Burnth: invalid header prefix length");
        require(
            keccak256(abi.encodePacked(proof.header_prefix, proof.state_root, proof.header_postfix))
                == blockhash(proof.blockNumber),
            "Burnth: invalid block hash"
        );

        require(!nullifiers[proof.nullifier], "Burnth: nullifier already used");
        nullifiers[proof.nullifier] = true;

        require(
            mpt_middle_verifier.verifyProof(
                proof.rootProof.a,
                proof.rootProof.b,
                proof.rootProof.c,
                [uint256(bytes32(proof.state_root)) % FIELD_SIZE, proof.layers[proof.layers.length - 1]]
            ),
            "MptRootVerifier: invalid proof"
        );

        for (uint256 i = 0; i < proof.layers.length - 1; i++) {
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
                [proof.layers[0], proof.coin, proof.nullifier, is_encrypted]
            ),
            "MptLastVerifier: invalid proof"
        );
    }

    function mint(PrivateProofOfBurn calldata proof) external {
        verify_proof(proof);

        if (proof.isEncrypted) {
            coins[proof.coin] = true;
            emit CoinGenerated(proof.target, proof.coin);
        } else {
            _mint(proof.target, proof.coin);
        }
    }

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
            spend_verifier.verifyProof(proof.a, proof.b, proof.c, [coin, remainingCoin, withdrawnBalance]),
            "SpendVerifier: invalid proof"
        );

        coins[remainingCoin] = true;
        _mint(destination, withdrawnBalance);

        emit CoinSpent(msg.sender, coin, remainingCoin, withdrawnBalance, destination);
        emit CoinGenerated(destination, remainingCoin);
    }
}
