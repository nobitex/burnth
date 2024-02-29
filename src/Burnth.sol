// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract Burnth is IERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "Burnth";
    string public symbol = "BUTH";
    uint8 public decimals = 18;

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

    mapping(uint256 => bool) public nullifiers;
    mapping(uint256 => bool) public coins;

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
    }

    // signal input balance;
    // signal input salt;
    // signal output coin;
    // coin <== hash(balance, salt)
    // signal input withdrawnBalance;
    // signal output remainingCoin;
    // remainingCoin <== hash(balance - withdrawnBalance, salt)
    // (withdrawnBalance should also be public)
    function spend(uint256 coin, uint256 remainingCoin, uint256 withdrawnBalance, address destination) external {
        // Check if coins[coin] is true

        // Falsify the coin: coins[coin] = false;

        // A ZK proof should check validity (Public input: [coin, withdrawnBalance, remainingCoin])

        // Add remaining coin: coins[remainingCoin] = true;

        // If everything is ok:
        // balanceOf[msg.sender] += withdrawnBalance;
        // totalSupply += withdrawnBalance;
        // emit Transfer(address(0), msg.sender, withdrawnBalance);
    }
}
