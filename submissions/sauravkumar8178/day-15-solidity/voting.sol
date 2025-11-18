// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Voting {
    address public immutable owner;     
    uint32  public immutable startAt;    
    uint32  public immutable endAt;      
    uint16  public immutable proposalCount; 
    struct Proposal { bytes32 name; uint32 votes; } 
    Proposal[] public proposals;

    mapping(address => uint256) public ballot;

    event Voted(address indexed voter, uint256 indexed proposalId);
    event ProposalAdded(uint256 indexed proposalId, bytes32 name);

    constructor(bytes32[] memory names, uint32 durationSeconds) {
        require(names.length > 0 && names.length <= 65535, "invalid proposals");
        owner = msg.sender;
        uint32 now32 = uint32(block.timestamp);
        startAt = now32;
        endAt = now32 + durationSeconds;
        proposalCount = uint16(names.length);

        proposals = new Proposal[](names.length);
        for (uint256 i = 0; i < names.length; ++i) {
            proposals[i].name = names[i];
            emit ProposalAdded(i, names[i]);
        }
    }

    function vote(uint256 proposalId) external {
        require(block.timestamp >= startAt && block.timestamp <= endAt, "voting closed");
        require(proposalId < proposals.length, "invalid proposal");
        require(ballot[msg.sender] == 0, "already voted");

        ballot[msg.sender] = proposalId + 1;

        unchecked { ++proposals[proposalId].votes; }

        emit Voted(msg.sender, proposalId);
    }

    function winningProposal() external view returns (uint256 winnerId, bytes32 name, uint32 votes) {
        uint256 best = 0;
        uint32 bestVotes = 0;
        uint256 len = proposals.length;
        for (uint256 i = 0; i < len; ++i) {
            uint32 v = proposals[i].votes;
            if (v > bestVotes) {
                bestVotes = v;
                best = i;
            }
        }
        return (best, proposals[best].name, bestVotes);
    }

    function getProposal(uint256 proposalId) external view returns (bytes32 name, uint32 votes) {
        require(proposalId < proposals.length, "invalid proposal");
        Proposal storage p = proposals[proposalId];
        return (p.name, p.votes);
    }

    function hasVoted(address who) external view returns (bool voted, uint256 proposalId) {
        uint256 b = ballot[who];
        if (b == 0) return (false, type(uint256).max);
        return (true, b - 1);
    }
}
