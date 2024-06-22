// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {WormCash} from "../src/contracts/WormCash.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

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

contract WormCashTest is Test {
    WormCash public worm_cash;

    function setUp() public {
        IERC20 token = IERC20(new SimpleToken());
        worm_cash = new WormCash(token);
    }

    function test_reward() public {
        assertEq(worm_cash.rewardOf(0), 50_000_000_000);
        assertEq(worm_cash.rewardOf(0), 50_000_000_000);
        assertEq(worm_cash.rewardOf(1), 49_999_999_995);
        assertEq(worm_cash.rewardOf(1), 49_999_999_995);
        assertEq(worm_cash.rewardOf(10), 49_999_999_959);
        assertEq(worm_cash.rewardOf(2), 49_999_999_991);
    }
}
