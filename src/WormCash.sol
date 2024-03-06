// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
contract WormCash is ERC20 {
    IERC20 burnth_contract;
    uint256 starting_block;
    address sender = msg.sender;

    mapping(uint256 => uint256) public epoch_totals;
    mapping(uint256 => mapping(address => uint256)) public epochs;

    constructor(IERC20 _burnth_addr) ERC20("WormCash", "WRM") {
        burnth_contract = _burnth_addr;
        starting_block = block.number;
    }

    uint256 constant BLOCK_PER_EPOCH = 10;
    uint256 constant MAX_REWARD = 50_000_000_000_000_000_000;
    uint256 constant REWARD_DECREASE_RATE = 10000000000;

    function currentEpoch() public view returns (uint256) {
        return (block.number - starting_block) / BLOCK_PER_EPOCH;
    }

    function approximate(uint256 amount_per_epoch, uint256 num_epochs) public view returns (uint256) {
        uint256 mint_amount = 0;
        uint256 currEpoch = currentEpoch();
        for (uint256 i = 0; i < num_epochs; i++) {
            uint256 epochIndex = currEpoch + i;
            uint256 user = epochs[epochIndex][sender] + amount_per_epoch;
            uint256 total = epoch_totals[epochIndex] + amount_per_epoch;
            mint_amount += rewardOf(epochIndex) * user / total;
        }
        return mint_amount;
    }

    function rewardOf(uint256 _epoch) public pure returns (uint256) {
        uint256 reward = MAX_REWARD;
        for (uint256 i = 0; i < _epoch; i++) {
            reward = reward - reward / REWARD_DECREASE_RATE;
        }
        return reward;
    }

    function participate(uint256 amount_per_epoch, uint256 num_epochs) external {
        uint256 currEpoch = currentEpoch();
        for (uint256 i = 0; i < num_epochs; i++) {
            epoch_totals[currEpoch + i] += amount_per_epoch;
            epochs[currEpoch + i][sender] += amount_per_epoch;
        }
        burnth_contract.transferFrom(sender, address(this), num_epochs * amount_per_epoch); // TODO: Handle exception
    }

    function claim(uint256 starting_epoch, uint256 num_epochs) external {
        require(starting_epoch + num_epochs <= currentEpoch(), "Cannot claim an ongoing epoch!");
        uint256 mint_amount = 0;
        for (uint256 i = 0; i < num_epochs; i++) {
            uint256 total = epoch_totals[starting_epoch + i];
            if (total > 0) {
                uint256 user = epochs[starting_epoch + i][sender];
                epochs[i][sender] = 0;
                mint_amount += rewardOf(starting_epoch + i) * user / total;
            }
        }
        _mint(sender, mint_amount);
    }
}
