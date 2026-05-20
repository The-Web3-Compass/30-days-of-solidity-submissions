// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedGovernance {

    struct Proposal {
        string description;
        uint256 voteCount;
        uint256 deadline;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public proposalCount;

    event ProposalCreated(uint256 proposalId, string description);
    event Voted(address voter, uint256 proposalId);
    event ProposalExecuted(uint256 proposalId);

    /*
     * Assign voting power (tokens simulation)
     */
    function assignVotingPower(address user, uint256 power) external {
        votingPower[user] += power;
    }

    /*
     * Create proposal
     */
    function createProposal(string memory _description, uint256 duration) external {

        require(votingPower[msg.sender] > 0, "No voting power");

        proposalCount++;

        proposals[proposalCount] = Proposal({
            description: _description,
            voteCount: 0,
            deadline: block.timestamp + duration,
            executed: false
        });

        emit ProposalCreated(proposalCount, _description);
    }

    /*
     * Vote on proposal
     */
    function vote(uint256 proposalId) external {

        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp < proposal.deadline, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(votingPower[msg.sender] > 0, "No voting power");

        proposal.voteCount += votingPower[msg.sender];
        hasVoted[proposalId][msg.sender] = true;

        emit Voted(msg.sender, proposalId);
    }

    /*
     * Execute proposal
     */
    function executeProposal(uint256 proposalId) external {

        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp >= proposal.deadline, "Voting still active");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }

    /*
     * View proposal details
     */
    function getProposal(uint256 proposalId)
        external
        view
        returns (string memory, uint256, uint256, bool)
    {
        Proposal memory p = proposals[proposalId];
        return (p.description, p.voteCount, p.deadline, p.executed);
    }
}