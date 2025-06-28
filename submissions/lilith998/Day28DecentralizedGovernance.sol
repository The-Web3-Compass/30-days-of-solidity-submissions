// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DAOVoting {
    struct Proposal {
        uint id;
        string description;
        uint voteCount;
        bool exists;
    }

    struct Voter {
        bool isMember;
        bool hasVoted;
        uint votedProposalId;
    }

    address public admin;
    uint public proposalCount;
    mapping(uint => Proposal) public proposals;
    mapping(address => Voter) public voters;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(voters[msg.sender].isMember, "Only members can vote");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addMember(address _member) external onlyAdmin {
        voters[_member].isMember = true;
    }

    function createProposal(string calldata _description) external onlyMember {
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: _description,
            voteCount: 0,
            exists: true
        });
        proposalCount++;
    }

    function vote(uint _proposalId) external onlyMember {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        require(!voters[msg.sender].hasVoted, "You have already voted");

        proposals[_proposalId].voteCount++;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
    }

    function getProposal(uint _proposalId) external view returns (string memory description, uint voteCount) {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        Proposal memory p = proposals[_proposalId];
        return (p.description, p.voteCount);
    }

    function resetVotes() external onlyAdmin {
        for (uint i = 0; i < proposalCount; i++) {
            proposals[i].voteCount = 0;
        }

        for (uint i = 0; i < proposalCount; i++) {
            for (uint j = 0; j < proposalCount; j++) {
                // There is no efficient way to reset all voters on-chain without gas explosion.
                // Would typically use off-chain solutions or reset individual members manually.
            }
        }
    }
}
