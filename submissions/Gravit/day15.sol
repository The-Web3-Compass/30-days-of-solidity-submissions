// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasSaver {
    address public owner;
    uint public proposalCount; 

    enum ProposalStatus {
        active,
        inactive
    }

    enum VoteOption {
        Yes,
        No
    }

    event ProposalCreated(string);
    event Voted(address, uint, VoteOption);
    event ProposalClosed(uint proposalId);

    struct Proposal {
        string name;
        uint yesVotes;
        uint noVotes;
        ProposalStatus status;
    }

    // Mappings
    mapping(uint => Proposal) public proposals;

    mapping(address => bool) public hasVoted;

    mapping(address => uint) public VotesPerUser;

    constructor() {
        owner = msg.sender;
    }

    function createProposal(string calldata _name) external {
        proposals[proposalCount] = Proposal({
            name: _name,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.active
        }); 
        proposalCount++;
        emit ProposalCreated(_name);
    }

    function vote(uint proposalId, VoteOption choice) external {
        Proposal storage proposal = proposals[proposalId]; 
        require(
            proposal.status == ProposalStatus.active,
            "Proposal is Inactive"
        );
        require(!hasVoted[msg.sender], "Already voted");
        if (choice == VoteOption.Yes) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        VotesPerUser[msg.sender]++;

        hasVoted[msg.sender] = true;
        emit Voted(msg.sender, proposalId, choice);
    }

    function getProposal(
        uint proposalId
    )
        external
        view
        returns (
            string memory name,
            uint yesVotes,
            uint noVotes,
            ProposalStatus status
        )
    {
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.name,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.status
        );
    }

    function checkIfVoted(address user) external view returns (bool) {
        return hasVoted[user];
    }

    function closeProposal(uint proposalId) external {
        require(msg.sender == owner, "Only Owner can close proposals");
        proposals[proposalId].status = ProposalStatus.inactive;
        emit ProposalClosed(proposalId);
    }

    function votesCountsPerUser(address _user) public returns (uint) {
        return VotesPerUser[_user];
    }
}