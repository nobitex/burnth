// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract Betther is IERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "Betther";
    string public symbol = "BETH";
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

    IERC20 burnth_contract;
    uint256 starting_block;

    constructor(address _burnth_addr) {
        burnth_contract = IERC20(_burnth_addr);
        starting_block = block.number;
        rewards[0] = 50_000_000_000;
    }

    uint256 constant BLOCK_PER_EPOCH = 10;

    mapping(uint256 => uint256) public rewards;
    mapping(uint256 => uint256) public epoch_totals;
    mapping(uint256 => mapping(address => uint256)) public epochs;

    function currentEpoch() public view returns (uint256) {
        return (block.number - starting_block) / BLOCK_PER_EPOCH;
    }

    function rewardOf(uint256 _epoch) internal returns (uint256) {
        uint256 i = _epoch;
        while (rewards[i] == 0) {
            i -= 1;
        }
        i += 1;
        while (i <= _epoch) {
            rewards[i] = rewards[i - 1] - rewards[i - 1] / 100000000;
            i += 1;
        }

        return rewards[_epoch];
    }

    function participate(address burner, uint256[] calldata amounts) external {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            epoch_totals[currentEpoch() + i] += amounts[i];
            epochs[currentEpoch() + i][burner] += amounts[i];
            total += amounts[i];
        }
        burnth_contract.transferFrom(burner, address(0), total); // TODO: Handle exception
    }

    function claim(uint256 epoch) external {
        uint256 total = epoch_totals[epoch];
        uint256 user = epochs[epoch][msg.sender];
        epochs[epoch][msg.sender] = 0;
        uint256 mint_amount = rewardOf(epoch) * user / total;
        balanceOf[msg.sender] += mint_amount;
        totalSupply += mint_amount;
        emit Transfer(address(0), msg.sender, mint_amount);
    }
}
