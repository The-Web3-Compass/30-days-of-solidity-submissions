// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedGovernance
 * @dev A simple DAO-style governance system where token holders can create and vote on proposals.
 * Demonstrates decentralized voting and proposal execution.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedGovernance is Ownable {
    IERC20 public governanceToken; // Token used for voting power

    uint256 public proposalCount;

    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
        bool executed;
        address proposer;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed id, string title, address proposer);
    event Voted(uint256 indexed id, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed id, bool passed);

    constructor(address _governanceToken) Ownable(msg.sender) {
        governanceToken = IERC20(_governanceToken);
    }

    /**
     * @dev Create a new proposal.
     */
    function createProposal(string memory _title, string memory _description, uint256 _duration) external {
        require(_duration > 0, "Duration must be > 0");

        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.id = proposalCount;
        proposal.title = _title;
        proposal.description = _description;
        proposal.deadline = block.timestamp + _duration;
        proposal.proposer = msg.sender;

        emit ProposalCreated(proposalCount, _title, msg.sender);
    }

    /**
     * @dev Vote on a proposal. Votes are weighted by token balance.
     */
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "Voting period ended");
        require(!proposal.voted[msg.sender], "Already voted");

        uint256 voterWeight = governanceToken.balanceOf(msg.sender);
        require(voterWeight > 0, "No voting power");

        proposal.voted[msg.sender] = true;

        if (_support) {
            proposal.yesVotes += voterWeight;
        } else {
            proposal.noVotes += voterWeight;
        }

        emit Voted(_proposalId, msg.sender, _support, voterWeight);
    }

    /**
     * @dev Execute a proposal after voting ends.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline, "Voting still active");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;

        bool passed = proposal.yesVotes > proposal.noVotes;

        // Here you could add logic for proposal actions, like fund transfers or parameter changes
        emit ProposalExecuted(_proposalId, passed);
    }

    /**
     * @dev View proposal details (simplified for front-end use)
     */
    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            string memory title,
            string memory description,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 deadline,
            bool executed,
            address proposer
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (p.id, p.title, p.description, p.yesVotes, p.noVotes, p.deadline, p.executed, p.proposer);
    }
}
