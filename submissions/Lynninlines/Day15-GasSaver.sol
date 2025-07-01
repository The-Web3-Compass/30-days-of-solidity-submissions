// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasSaverVoting {
    struct Proposal {
        bytes32 descriptionHash;
        uint32 endTime;
        uint32 yesVotes;
        uint32 noVotes;
        uint8 status;
    }

    Proposal[] public proposals;
    mapping(uint256 => mapping(uint256 => uint256)) private voteBitmaps;
    
    event ProposalCreated(uint256 indexed proposalId, bytes32 descriptionHash, uint32 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalEnded(uint256 indexed proposalId, uint32 yesVotes, uint32 noVotes);

    function createProposal(bytes calldata description, uint32 durationMinutes) external {
        uint32 endTime = uint32(block.timestamp + durationMinutes * 60);
        bytes32 descriptionHash = keccak256(description);
        proposals.push(Proposal(descriptionHash, endTime, 0, 0, 1));
        emit ProposalCreated(proposals.length, descriptionHash, endTime);
    }

    function vote(uint256 proposalId, bool support) external {
        require(proposalId > 0 && proposalId <= proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId - 1];
        require(proposal.status == 1, "Proposal closed");
        require(block.timestamp < proposal.endTime, "Voting ended");
        require(!hasVoted(proposalId, msg.sender), "Already voted");
        _markVoted(proposalId, msg.sender);
        if (support) proposal.yesVotes++;
        else proposal.noVotes++;
        emit Voted(proposalId, msg.sender, support);
    }

    function endProposal(uint256 proposalId) external {
        require(proposalId > 0 && proposalId <= proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId - 1];
        require(proposal.status == 1, "Already ended");
        require(block.timestamp >= proposal.endTime, "Voting ongoing");
        proposal.status = 2;
        emit ProposalEnded(proposalId, proposal.yesVotes, proposal.noVotes);
    }

    function hasVoted(uint256 proposalId, address voter) public view returns (bool) {
        (uint256 bucket, uint256 mask) = _bitmapPosition(voter);
        return voteBitmaps[proposalId][bucket] & mask != 0;
    }

    function getProposal(uint256 proposalId) external view returns (
        bytes32 descriptionHash,
        uint32 endTime,
        uint32 yesVotes,
        uint32 noVotes,
        uint8 status
    ) {
        require(proposalId > 0 && proposalId <= proposals.length, "Invalid proposal");
        Proposal storage p = proposals[proposalId - 1];
        return (p.descriptionHash, p.endTime, p.yesVotes, p.noVotes, p.status);
    }

    function _bitmapPosition(address voter) private pure returns (uint256 bucket, uint256 mask) {
        uint256 pos = uint256(keccak256(abi.encodePacked(voter)));
        bucket = pos >> 8;
        mask = 1 << (pos & 0xFF);
    }

    function _markVoted(uint256 proposalId, address voter) private {
        (uint256 bucket, uint256 mask) = _bitmapPosition(voter);
        voteBitmaps[proposalId][bucket] |= mask;
    }
}
