// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract ETHPool {
    address public team;  // Team's address
    uint256 public totalDeposits;  // Total ETH deposited by users
    uint256 public totalRewards;   // Accumulated rewards

    mapping(address => uint256) public deposits;    // Track each user's deposits
    mapping(address => uint256) public rewardDebt;  // Track user's reward debt for withdrawal

    modifier onlyTeam() {
        require(msg.sender == team, "Only team can perform this action");
        _;
    }

    constructor(address _team) {
        team = _team;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount should be greater than 0");

        // Calculate pending rewards for previous deposits
        uint256 userShare = deposits[msg.sender];
        if (userShare > 0) {
            uint256 pendingReward = (userShare * totalRewards) / totalDeposits;
            rewardDebt[msg.sender] += pendingReward;
        }

        // Update user's deposit and total deposits
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function depositRewards() external payable onlyTeam {
        require(totalDeposits > 0, "No deposits in the pool");
        require(msg.value > 0, "Reward amount should be greater than 0");

        // Update total rewards
        totalRewards += msg.value;
    }

    function withdraw() external {
        uint256 userDeposit = deposits[msg.sender];
        require(userDeposit > 0, "No deposit to withdraw");

        // Calculate user's rewards
        uint256 userReward = (userDeposit * totalRewards) / totalDeposits;
        uint256 payout = userDeposit + rewardDebt[msg.sender] + userReward;

        // Update pool state
        totalDeposits -= userDeposit;
        totalRewards -= userReward;
        deposits[msg.sender] = 0;
        rewardDebt[msg.sender] = 0;

        // Transfer ETH to the user
        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Withdrawal failed");
    }
}
