//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Gassaver
 * @author Eric (https://github.com/0xxEric)
 * @notice Gas saved  Voting
 * @custom:project 30-days-of-solidity-submissions: Day15
 */

contract GasEfficientVoting {
    address public admin;
    uint8 public proposalId;
    mapping(uint8 => Proposal) public proposals;
    mapping(address => uint256) private voterRegistry;
    event ProposalSet(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed votor, uint8 indexed id);

    struct Proposal {
        bytes32 name;
        uint32 voteCount;
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    constructor() {
        admin = msg.sender;
    }

    modifier Onlyadmin() {
        require(msg.sender == admin, "Only admin can set candidates");
        _;
    }

    function setNewProposal(bytes32 _name, uint32 duration) external Onlyadmin {
        require(duration > 100, "Voting time too short");
        require(_name!= bytes32(0), "empty name");
        proposalId++;
        Proposal memory p = Proposal({
            name: _name,
            voteCount: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            executed: false
        });
        proposals[proposalId] = p;
        emit ProposalSet(proposalId, _name);
    }

    function vote(uint8 id) external {
        require(id > 0 &&id < proposalId, "Invalid Proposal");
        uint32 currentTime = uint32(block.timestamp);
        require(
            currentTime >= proposals[id].startTime,
            "Voting has not started"
        );
        require(
            currentTime <= proposals[id].endTime,
            "Voting has ended"
        );

        uint256 voterData = voterRegistry[msg.sender];
        uint256 mask = 1 << id;
        require((voterRegistry[msg.sender] & mask) == 0, "Already voted");
        voterRegistry[msg.sender] = voterData | mask;
        proposals[id].voteCount++;
        proposals[id].voteCount++;

        emit Voted(msg.sender, id);
    }

    function executeProposal(uint8 id) external Onlyadmin {
        require(id < proposalId, "Invalid Proposal");
        require(block.timestamp > proposals[id].endTime, "Voting not ended ");
        require(!proposals[id].executed, "Already executed");
        proposals[id].executed = true;
        emit ProposalExecuted(id);
    }

    function hasVoted(address voter, uint8 id) external view returns (bool) {
        return (voterRegistry[voter] & (1 << id) != 0);
    }

    function getProposal(
        uint8 id
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
        require(id < proposalId, "Invalid proposal");

        Proposal storage proposal = proposals[id];
        return (
            proposal.name,
            proposal.voteCount,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            (block.timestamp >= proposal.startTime &&
                block.timestamp <= proposal.endTime)
        );
    }
}
