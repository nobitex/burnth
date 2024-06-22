// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract WormCash is ERC20 {
    IERC20 public burnth_contract;
    uint256 public starting_block;

    mapping(uint256 => uint256) public epoch_totals;
    mapping(uint256 => mapping(address => uint256)) public epochs;

    constructor(IERC20 _burnth_addr) ERC20("WormCash", "WRM") {
        burnth_contract = _burnth_addr;
        starting_block = block.number;
    }

    uint256 constant BLOCK_PER_EPOCH = 10;
    uint256 constant MAX_REWARD = 50_000_000_000_000_000_000;
    uint256 constant REWARD_DECREASE_RATE = 10000000000;

    /**
     * @notice Returns the current epoch number based on the starting block and blocks per epoch.
     *
     * @dev The epoch number is calculated by dividing the number of blocks since the starting block by the number of blocks per epoch.
     *
     * @return The current epoch number.
     */
    function currentEpoch() public view returns (uint256) {
        return (block.number - starting_block) / BLOCK_PER_EPOCH;
    }

    /**
     * @notice Estimates the amount of tokens that can be minted for a given participation over multiple epochs.
     *
     * @dev This function calculates the approximate mint amount based on the user's participation and the total participation in each epoch.
     *
     * @param _amount_per_epoch The amount the user plans to participate per epoch.
     * @param _num_epochs The number of epochs the user plans to participate in.
     * @return The approximate amount of tokens that can be minted.
     */
    function approximate(
        uint256 _amount_per_epoch,
        uint256 _num_epochs
    ) public view returns (uint256) {
        uint256 mint_amount = 0;
        uint256 currEpoch = currentEpoch();
        for (uint256 i = 0; i < _num_epochs; i++) {
            uint256 epochIndex = currEpoch + i;
            uint256 user = epochs[epochIndex][msg.sender] + _amount_per_epoch;
            uint256 total = epoch_totals[epochIndex] + _amount_per_epoch;
            mint_amount += (rewardOf(epochIndex) * user) / total;
        }
        return mint_amount;
    }

    /**
     * @notice Calculates the reward for a given epoch.
     *
     * @dev The reward decreases by a fixed rate every epoch.
     *
     * @param _epoch The epoch number for which to calculate the reward.
     * @return The reward for the given epoch.
     */
    function rewardOf(uint256 _epoch) public pure returns (uint256) {
        uint256 reward = MAX_REWARD;
        for (uint256 i = 0; i < _epoch; i++) {
            reward = reward - reward / REWARD_DECREASE_RATE;
        }
        return reward;
    }

    /**
     * @notice Allows a user to participate in the reward program by locking tokens for multiple epochs.
     *
     * @dev This function updates the user's participation in the specified number of epochs and transfers the required amount of Burnth tokens to the contract.
     *
     * @param _amount_per_epoch The amount of tokens to lock per epoch.
     * @param _num_epochs The number of epochs to participate in.
     */
    function participate(
        uint256 _amount_per_epoch,
        uint256 _num_epochs
    ) external {
        require(_num_epochs != 0, "Invalid epoch number.");
        uint256 currEpoch = currentEpoch();
        for (uint256 i = 0; i < _num_epochs; i++) {
            epoch_totals[currEpoch + i] += _amount_per_epoch;
            epochs[currEpoch + i][msg.sender] += _amount_per_epoch;
        }
        burnth_contract.transferFrom(
            msg.sender,
            address(this),
            _num_epochs * _amount_per_epoch
        );
    }

    /**
     * @notice Allows a user to get the claim amount of their rewards for participation in past epochs.
     *
     * @dev This function calculates and mints the reward based on the user's participation and the total participation in each epoch.
     *
     * @param _starting_epoch The starting epoch number from which to claim rewards.
     * @param _num_epochs The number of epochs to claim rewards for.
     * @param _user The user address.
     */
    function calculateMintAmount(uint256 _starting_epoch, uint256 _num_epochs, address _user) public view returns(uint256){
        require(
            _starting_epoch + _num_epochs <= currentEpoch(),
            "Cannot claim an ongoing epoch!"
        );
        uint256 mint_amount = 0;
        for (uint256 i = 0; i < _num_epochs; i++) {
            uint256 total = epoch_totals[_starting_epoch + i];
            if (total > 0) {
                uint256 user = epochs[_starting_epoch + i][_user];
                mint_amount += (rewardOf(_starting_epoch + i) * user) / total;
            }
        }
        return mint_amount;
    }

        /**
     * @notice Allows a user to claim their rewards for participation in past epochs.
     *
     * @dev This function calculates and mints the reward based on the user's participation and the total participation in each epoch.
     *
     * @param _starting_epoch The starting epoch number from which to claim rewards.
     * @param _num_epochs The number of epochs to claim rewards for.
     */
    function claim(uint256 _starting_epoch, uint256 _num_epochs) external returns(uint256){
        uint256 mint_amount = calculateMintAmount(_starting_epoch, _num_epochs, msg.sender);
        _mint(msg.sender, mint_amount);
        return mint_amount;
    }
}
