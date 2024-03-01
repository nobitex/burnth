// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "./MptFirstVerifier.sol";
import "./MptLastVerifier.sol";
import "./SpendVerifier.sol";
import "./Console.sol";

contract Burnth is IERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "Burnth";
    string public symbol = "BUTH";
    uint8 public decimals = 18;

    uint256 constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    
    struct Groth16Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    struct PrivateProofOfBurn {
        uint256 blockNumber; // Argument on blockRoot of which block?
        uint256 coin; // Coin is stealth version of balance (If `isEncrypted`): hash(balance, salt)
        uint256 nullifier; // Nullifier is based on the preimage: nullifier = mimc7(preimage, 0)
        uint256[] layers;
        Groth16Proof firstProof;
        Groth16Proof[] midProofs;
        Groth16Proof lastProof;
        bool isEncrypted; // true if `coin` == hash(balance, salt). false if `coin` == `balance`
        address target; // Target address will get the minted tokens.
    }

    SpendVerifier spend_verifier = new SpendVerifier();
    MptLastVerifier mpt_last_verifier = new MptLastVerifier();
    MptFirstVerifier mpt_first_verifier = new MptFirstVerifier();
    mapping(uint256 => bool) public nullifiers;
    mapping(uint256 => bool) public coins;

    event CoinGenerated(address recipient, uint256 coin);
    event CoinSpent(address spender, uint256 coin, uint256 remainingCoin, uint256 withdrawnBalance, address destination);

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function verify_proof(PrivateProofOfBurn calldata proof) internal {
        uint256 block_hash = uint256(blockhash(proof.blockNumber)) % FIELD_SIZE;
        uint256 is_encrypted = proof.isEncrypted ? 1 : 0;

        require(!nullifiers[proof.nullifier], "Burnth: nullifier already used");
        nullifiers[proof.nullifier] = true;

        require(mpt_first_verifier.verifyProof(
            proof.firstProof.a,
            proof.firstProof.b,
            proof.firstProof.c,
            [block_hash]
        ), "MptFirstVerifier: invalid proof");

        // TODO: fix last layer verifier
        // require(mpt_last_verifier.verifyProof(
        //     proof.lastProof.a,
        //     proof.lastProof.b,
        //     proof.lastProof.c,
        //     [, proof.coin, proof.nullifier, is_encrypted]
        // ), "MptLastVerifier: invalid proof");
    }

    function mint(PrivateProofOfBurn calldata proof) external {
        // Check if nullifiers[proof.nullifier] == false
        // Verify the proof given public inputs:
        //  - bytes32 blockhash = blockhash(proof.blockNumber);
        //  - MptFirst public inputs: [blockhash, layers[0]]
        //  - MptPaths public inputs: [layers[i], layers[i+1]]
        //  - MptLast public inputs: [layers[-1], coin, nullifier, isEncrypted]
        // If isEncrypted
        //   - Create a new encrypted coin: coins[proof.coin] = true;
        // Else
        //   - Mint `proof.coin` amount of coins and transfer to `target`

        // verify proof
        verify_proof(proof);

        if (proof.isEncrypted) {
            coins[proof.coin] = true;
            emit CoinGenerated(proof.target, proof.coin);
        } else {
            balanceOf[proof.target] += proof.coin;
            totalSupply += proof.coin;
            emit Transfer(address(0), proof.target, proof.coin);
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

        require(spend_verifier.verifyProof(
            proof.a,
            proof.b,
            proof.c,
            [coin, remainingCoin, withdrawnBalance]
        ), "SpendVerifier: invalid proof");

        coins[remainingCoin] = true;
        balanceOf[destination] += withdrawnBalance;
        totalSupply += withdrawnBalance;

        emit CoinSpent(msg.sender, coin, remainingCoin, withdrawnBalance, destination);
        emit CoinGenerated(destination, remainingCoin);
        emit Transfer(address(0), destination, withdrawnBalance);
    }
}
