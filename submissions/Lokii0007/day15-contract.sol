// SPDX-License-Identifier:MIT

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

    mapping(uint8 => Proposal) public proposals;
    mapping(address => uint256) private voterRegistry;
    mapping(uint8 => uint32) public proposalVoterCount;

    event ProposalCreated(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    function createProposal(uint32 _duration, bytes32 _name) external {
        require(_duration > 0, "durtion must be greater than 0");

        uint8 proposalId = proposalCount;
        proposalCount++;
        Proposal memory newProposal = Proposal({
            name: _name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: _duration + uint32(block.timestamp),
            executed: false
        });
        proposals[proposalId] = newProposal;

        emit ProposalCreated(proposalId, _name);
    }

    function vote(uint8 _proposalId) external {
        require(_proposalId < proposalCount, "invalid proposal");
        require(
            uint32(block.timestamp) >= proposals[_proposalId].startTime,
            "votiung hasnt started yet"
        );
        require(
            uint32(block.timestamp) <= proposals[_proposalId].endTime,
            "votiung hasnt started yet"
        );

        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << _proposalId;

        require((voterRegistry[msg.sender] & mask) == 0, "already voted");

        voterRegistry[msg.sender] = voterData | mask;
        proposals[_proposalId].voteCount++;
        proposalVoterCount[_proposalId]++;

        emit Voted(msg.sender, _proposalId);
    }

    function executeProposal(uint8 _proposalId) external {
        require(_proposalId < proposalCount, "invalid proposal");
        require(
            uint32(block.timestamp) >= proposals[_proposalId].startTime,
            "votiung hasnt started yet"
        );
        require(
            uint32(block.timestamp) <= proposals[_proposalId].endTime,
            "votiung hasnt started yet"
        );
        require(!proposals[_proposalId].executed, "already execited");

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function hasVoted(
        address _voter,
        uint _proposalId
    ) external view returns (bool) {
        return (voterRegistry[_voter] & (1 << _proposalId) != 0);
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
        require(_proposalId < proposalCount, "invalid proposal");
        Proposal storage proposal = proposals[_proposalId];

        return(
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            (uint32(block.timestamp) >= proposal.startTime && uint32(block.timestamp) <= proposal.endTime )
        );
    }
}
