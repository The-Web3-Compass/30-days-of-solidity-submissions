//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEfficientVoting {
    uint8 public proposalCount;

    //using minimal space types
    struct Proposal {
        //string name;
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool ended;
    }

    // using mapping is more gas efficient
    mapping(uint8 => Proposal) public proposals;

    // Single-slot packed user data
    // Using a single uint8 number to record voting flags for gas efficiency, each bit represents a vote
    mapping(address => uint8) private voteRegistry;

    mapping(uint8 => uint32) public proposalVoteCount;

    event ProposalCreated(uint8 indexed proposalID, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalID);
    event ProposalEnded(uint8 indexed proposalID);

    function createProposal(/*string calldata*/bytes32 _name, uint32 _duration) external {
        require(_duration > 0, "Proposal duration should be greater than 0");

        proposals[proposalCount] = Proposal({
            name: _name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + _duration,
            ended: false
        });

        emit ProposalCreated(proposalCount, _name);
        proposalCount++; // Increment counter - cheaper than .push() on an array
    }

    function vote(uint8 _proposalID) external {
        require(_proposalID < proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[_proposalID];
        uint32 currentTime = uint32(block.timestamp);
        require(currentTime >= proposal.startTime, "Voting not started yet");
        require(currentTime <= proposal.endTime, "Voting has already ended");

        uint8 voteData = voteRegistry[msg.sender];
        uint8 mask = uint8(1) << _proposalID;
        require((voteData & mask) == 0, "You have already voted");

        proposal.voteCount++;
        proposalVoteCount[_proposalID]++;
        voteRegistry[msg.sender] = voteData | mask; // record the vote for sender
        emit Voted(msg.sender, _proposalID);
    }

    function finilizeProposal(uint8 _proposalID) external {
        require(_proposalID < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalID];
        require(uint32(block.timestamp) > proposal.endTime, "End too early");
        require(!proposal.ended, "Proposal is already ended");

        proposal.ended = true;
        emit ProposalEnded(_proposalID);
    }

    function hasVoted(address _user, uint8 _proposalID) external view returns(bool) {
        require(_proposalID < proposalCount, "Invalid proposal ID");
        return (voteRegistry[_user] & (1 << _proposalID) != 0);
    }

    function getProposal(uint8 _proposalID) external view returns(
        //string memory name
        bytes32 name,
        uint32 voteCount,
        uint32 startTime,
        uint32 endTime,
        bool ended,
        bool active
    ) {
        require(_proposalID < proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[_proposalID];
        return (
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.ended,
            (block.timestamp <= proposal.endTime && block.timestamp >= proposal.startTime)
        );
    }
}