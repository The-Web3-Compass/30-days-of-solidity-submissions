// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasSaver {
    bytes32[] public proposals;
    uint256[] public votes;
    mapping(address => uint256) private votedBitmap;

    address public immutable admin;
    uint8 public immutable maxProposals;

    event ProposalAdded(bytes32 name, uint256 id);
    event Voted(address indexed voter, uint256 proposalId);

    constructor(bytes32[] memory initialProposals) {
        require(initialProposals.length > 0 && initialProposals.length <= 256, "bad count");
        admin = msg.sender;
        maxProposals = uint8(initialProposals.length);
        for (uint256 i = 0; i < initialProposals.length; ++i) {
            proposals.push(initialProposals[i]);
            votes.push(0);
            emit ProposalAdded(initialProposals[i], i);
        }
    }

    function addProposals(bytes32[] calldata names) external {
        require(msg.sender == admin, "only admin");
        uint256 len = names.length;
        require(proposals.length + len <= 256, "limit");
        for (uint256 i = 0; i < len; ++i) {
            proposals.push(names[i]);
            votes.push(0);
            emit ProposalAdded(names[i], proposals.length - 1);
        }
    }

    function vote(uint256 proposalId) external {
        uint256 pLen = proposals.length;
        require(proposalId < pLen, "invalid proposal");
        uint256 bitmap = votedBitmap[msg.sender];
        uint256 mask = uint256(1) << proposalId;
        require(bitmap & mask == 0, "already voted");
        votedBitmap[msg.sender] = bitmap | mask;
        unchecked { votes[proposalId] = votes[proposalId] + 1; }
        emit Voted(msg.sender, proposalId);
    }

    function getVotes(uint256 proposalId) external view returns (uint256) {
        require(proposalId < proposals.length, "invalid");
        return votes[proposalId];
    }

    function hasVoted(address who, uint256 proposalId) external view returns (bool) {
        require(proposalId < proposals.length, "invalid");
        return (votedBitmap[who] >> proposalId) & 1 == 1;
    }

    function getProposal(uint256 proposalId) external view returns (bytes32) {
        require(proposalId < proposals.length, "invalid");
        return proposals[proposalId];
    }
}
