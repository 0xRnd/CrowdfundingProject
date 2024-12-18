// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Crowdfunding is ReentrancyGuard {
    struct Campaign {
        address creator;
        string name;
        uint goal;
        uint deadline;
        uint totalContributed;
        bool isWithdrawn;
        mapping(address => uint) contributions;
    }

    uint public campaignCount;
    mapping(uint => Campaign) public campaigns;

    event CampaignCreated(
        uint campaignId,
        string name,
        uint goal,
        uint deadline
    );
    event ContributionReceived(
        uint campaignId,
        address indexed contributor,
        uint amount
    );
    event FundsWithdrawn(uint campaignId);
    event RefundIssued(
        uint campaignId,
        address indexed contributor,
        uint amount
    );

    // Errors
    error NameCannotBeEmpty();
    error GoalMustBeGreaterThanZero();
    error DurationMustBeGreaterThanZero();
    error CampaignDoesNotExist();
    error CampaignExpired();
    error ContributionMustBeGreaterThanZero();
    error OnlyCreatorCanWithdraw();
    error CampaignOngoing();
    error GoalNotMet();
    error FundsAlreadyWithdrawn();
    error NoContributionToRefund();
    error RefundFailed();
    error TransferFailed();

    function createCampaign(
        string calldata _name,
        uint _goal,
        uint _duration
    ) external {
        if (bytes(_name).length == 0) revert NameCannotBeEmpty();
        if (_goal == 0) revert GoalMustBeGreaterThanZero();
        if (_duration == 0) revert DurationMustBeGreaterThanZero();

        uint deadline = block.timestamp + _duration;

        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.creator = msg.sender;
        newCampaign.name = _name;
        newCampaign.goal = _goal;
        newCampaign.deadline = deadline;

        emit CampaignCreated(campaignCount, _name, _goal, deadline);
        campaignCount++;
    }

    function contribute(uint _campaignId) external payable {
        Campaign storage campaign = campaigns[_campaignId];
        if (_campaignId >= campaignCount) revert CampaignDoesNotExist();
        if (block.timestamp >= campaign.deadline) revert CampaignExpired();
        if (msg.value == 0) revert ContributionMustBeGreaterThanZero();

        campaign.contributions[msg.sender] += msg.value;
        campaign.totalContributed += msg.value;

        emit ContributionReceived(_campaignId, msg.sender, msg.value);
    }

    function withdrawFunds(uint _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        if (_campaignId >= campaignCount) revert CampaignDoesNotExist();
        if (msg.sender != campaign.creator) revert OnlyCreatorCanWithdraw();
        if (block.timestamp < campaign.deadline) revert CampaignOngoing();
        if (campaign.totalContributed < campaign.goal) revert GoalNotMet();
        if (campaign.isWithdrawn) revert FundsAlreadyWithdrawn();

        campaign.isWithdrawn = true;
        uint amount = campaign.totalContributed;

        emit FundsWithdrawn(_campaignId);
        (bool success, ) = campaign.creator.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function refund(uint _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        if (_campaignId >= campaignCount) revert CampaignDoesNotExist();
        if (block.timestamp < campaign.deadline) revert CampaignOngoing();
        if (campaign.totalContributed >= campaign.goal) revert GoalNotMet();
        uint amount = campaign.contributions[msg.sender];
        if (amount == 0) revert NoContributionToRefund();

        campaign.contributions[msg.sender] = 0;

        emit RefundIssued(_campaignId, msg.sender, amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert RefundFailed();
    }

    function getContribution(
        uint _campaignId,
        address _contributor
    ) external view returns (uint) {
        return campaigns[_campaignId].contributions[_contributor];
    }

    function getCampaign(
        uint _campaignId
    )
        external
        view
        returns (
            address creator,
            string memory name,
            uint goal,
            uint deadline,
            uint totalContributed,
            bool isWithdrawn
        )
    {
        Campaign storage campaign = campaigns[_campaignId]; // Load to memory once
        return (
            campaign.creator,
            campaign.name,
            campaign.goal,
            campaign.deadline,
            campaign.totalContributed,
            campaign.isWithdrawn
        );
    }
}
