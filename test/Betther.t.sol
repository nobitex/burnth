// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Betther} from "../src/Betther.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract SimpleToken is IERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "SimpleToken";
    string public symbol = "ST";
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
}

contract BettherTest is Test {
    Betther public betther;

    function setUp() public {
        IERC20 token = IERC20(new SimpleToken());
        betther = new Betther(token);
    }

    function test_reward() public {
        assertEq(betther.rewardOf(0), 50_000_000_000);
        assertEq(betther.rewardOf(0), 50_000_000_000);
        assertEq(betther.rewardOf(1), 49_999_999_995);
        assertEq(betther.rewardOf(1), 49_999_999_995);
        assertEq(betther.rewardOf(10), 49_999_999_959);
        assertEq(betther.rewardOf(2), 49_999_999_991);
    }
}