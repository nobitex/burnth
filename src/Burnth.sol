// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

contract Burnth is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Burnth";
    string public symbol = "BUTH";
    uint8 public decimals = 18;

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    struct Groth16Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
    }

    struct PrivateProofOfBurn {
        uint blockNumber; // Argument on blockRoot of which block?
        uint coin; // Coin is stealth version of balance: hash(balance, salt)
        uint[] layers;
        Groth16Proof firstProof;
        Groth16Proof[] midProofs;
        Groth16Proof lastProof;
    }

    mapping(uint => bool) public coins;

    function mintStealth(PrivateProofOfBurn calldata proof) external {
        // Verify the proof and create a new coin: coins[proof.coin] = true;
        // bytes32 blockhash = blockhash(proof.blockNumber);
    }

    // signal input balance;
    // signal input salt;
    // signal output coin;
    // coin <== hash(balance, salt)
    // signal input withdrawnBalance;
    // signal output remainingCoin;
    // remainingCoin <== hash(balance - withdrawnBalance, salt)
    // (withdrawnBalance should also be public)
    function mint(uint256 coin, uint256 remainingCoin, uint256 withdrawnBalance, address destination) external {
        // Check if coins[coin] is true

        // Falsify the coin: coins[coin] = false;

        // A ZK proof should check validity (Public input: [coin, withdrawnBalance, remainingCoin])
        
        // If everything is ok: 
        // balanceOf[msg.sender] += withdrawnBalance;
        // totalSupply += withdrawnBalance;
        // emit Transfer(address(0), msg.sender, withdrawnBalance);
    }
}