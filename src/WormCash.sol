// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract WormCash is ERC20 {
    IERC20 burnth_contract;
    uint256 starting_block;
    mapping(uint256 => uint256) public rewards;
    mapping(uint256 => uint256) public epoch_totals;
    mapping(uint256 => mapping(address => uint256)) public epochs;

    constructor(IERC20 _burnth_addr) ERC20("WormCash", "WRM") {
        burnth_contract = _burnth_addr;
        starting_block = block.number;
        rewards[0] = 50_000_000_000;
    }

    uint256 constant BLOCK_PER_EPOCH = 10;

    function currentEpoch() public view returns (uint256) {
        return (block.number - starting_block) / BLOCK_PER_EPOCH;
    }

    function rewardOf(uint256 _epoch) public returns (uint256) {
        uint256 i = _epoch;
        while (rewards[i] == 0) {
            i -= 1;
        }
        i += 1;
        while (i <= _epoch) {
            rewards[i] = rewards[i - 1] - rewards[i - 1] / 10000000000;
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
        _mint(msg.sender, mint_amount);
    }
}
