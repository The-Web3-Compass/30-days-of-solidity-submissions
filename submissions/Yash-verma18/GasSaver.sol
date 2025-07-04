// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasSaver {
    uint8 public proposalCount;
    struct Proposal {
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    // Maps proposal IDs to their corresponding Proposal struct
    // Used to store and retrieve all proposal details by ID
    mapping(uint8 => Proposal) public proposals;

    // Maps voter addresses to a packed uint256 that stores voting history
    // Each bit position represents whether the voter has voted for a specific proposal
    // This is a gas-efficient way to track which proposals a voter has participated in
    mapping(address => uint256) private voterRegistry;

    // Maps proposal IDs to the count of unique voters who participated in that proposal
    // Tracks how many different addresses have voted on each proposal
    mapping(uint8 => uint32) public proposalVoterCount;

    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    function createProposal(bytes32 _name, uint32 duration) external {
        require(duration > 0, "Duration must be greater than 0");
        uint8 proposalId = proposalCount;
        proposalCount++;
        Proposal memory newProposal = Proposal({
            name: _name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
        });
        proposals[proposalId] = newProposal;
        emit ProposalCreated(proposalId, _name);
    }

    function vote(uint8 _proposalId) external {
        uint32 currentTime = uint32(block.timestamp);
        require(_proposalId < proposalCount, "Invalid proposal ID");
        require(
            currentTime <= proposals[_proposalId].endTime,
            "Voting has ended"
        );

        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << _proposalId;
        require(voterRegistry[msg.sender] & mask == 0, "Already voted");
        voterRegistry[msg.sender] = voterData | mask;

        proposals[_proposalId].voteCount++;
        proposalVoterCount[_proposalId]++;
        emit Voted(msg.sender, _proposalId);
    }

    function executeProposal(uint8 _proposalId) external {
        require(_proposalId < proposalCount, "Invalid proposal ID");
        require(
            block.timestamp >= proposals[_proposalId].endTime,
            "Voting is still ongoing"
        );
        require(!proposals[_proposalId].executed, "Proposal already executed");
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function hasVoted(
        address _voter,
        uint8 _proposalId
    ) external view returns (bool) {
        // uint256 voterData = voterRegistry[_voter];
        // uint256 mask = 1 << _proposalId;
        // return (voterData & mask) != 0;

        return (voterRegistry[_voter] & (1 << _proposalId)) != 0;
    }

    function getProposal(
        uint8 _proposalId
    )
        external
        view
        returns (
            bytes32 name,
            uint32 voteCount,
            uint32 startTime,
            uint32 endTime,
            bool executed,
            bool active
        )
    {
        require(_proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            block.timestamp >= proposal.startTime &&
                block.timestamp <= proposal.endTime
        );
    }
}
