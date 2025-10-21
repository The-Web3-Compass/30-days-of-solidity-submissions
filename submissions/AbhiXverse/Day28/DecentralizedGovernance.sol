// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedGovernance {
    address public owner;
    uint public proposalCount;
    uint public memberCount;
    uint public quorumPercentage;

    mapping(address => bool) public isMember;
    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public hasVoted;
    mapping(uint => mapping(address => bool)) public memberVotes;

    enum ProposalState {
        Pending,
        Approved,
        Executed,
        Failed,
        Expired
    }

    struct Proposal {
        uint id;
        address proposer;
        string description;
        address targetContract;
        bytes callData;
        uint minExecutionDelay;
        uint deadline;
        uint createdTimestamp;
        uint approvedTimestamp;
        uint executedTimestamp;
        bytes executionResult;
        ProposalState state;
        uint yesVotes;
        uint noVotes;
    }

    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event ProposalCreated(uint indexed proposalId, address indexed proposer, address targetContract);
    event Voted(uint indexed proposalId, address indexed voter, bool voteYes);
    event ProposalStateChanged(uint indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint indexed proposalId, bool success, bytes result);
    event QuorumUpdated(uint newQuorumPercentage);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a member");
        _;
    }

    modifier proposalExists(uint _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        _;
    }

    modifier notVoted(uint _proposalId) {
        require(!hasVoted[_proposalId][msg.sender], "Already voted");
        _;
    }

    modifier inState(uint _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Wrong proposal state");
        _;
    }

    constructor(uint _initialQuorumPercentage) {
        require(_initialQuorumPercentage > 0 && _initialQuorumPercentage <= 100, "Invalid quorum");
        owner = msg.sender;
        quorumPercentage = _initialQuorumPercentage;
        isMember[owner] = true;
        memberCount = 1;

        emit MemberAdded(owner);
        emit QuorumUpdated(_initialQuorumPercentage);
    }

    function addMember(address _member) external onlyOwner {
        require(_member != address(0), "Zero address");
        require(!isMember[_member], "Already member");
        isMember[_member] = true;
        memberCount++;
        emit MemberAdded(_member);
    }

    function removeMember(address _member) external onlyOwner {
        require(_member != address(0), "Zero address");
        require(isMember[_member], "Not a member");
        require(_member != owner, "Cannot remove owner");
        isMember[_member] = false;
        memberCount--;
        emit MemberRemoved(_member);
    }

    function updateQuorum(uint _newQuorumPercentage) external onlyOwner {
        require(_newQuorumPercentage > 0 && _newQuorumPercentage <= 100, "Invalid quorum");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumUpdated(_newQuorumPercentage);
    }

    function createProposal(
        string memory _description,
        address _targetContract,
        bytes memory _callData,
        uint _minExecutionDelay,
        uint _deadline
    ) external onlyMember {
        require(bytes(_description).length > 0, "Empty description");
        if (_targetContract != address(0)) {
            require(_callData.length > 0, "Call data required");
        } else {
            require(_callData.length == 0, "Call data must be empty");
        }
        require(_deadline > block.timestamp, "Invalid deadline");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            minExecutionDelay: _minExecutionDelay,
            deadline: _deadline,
            createdTimestamp: block.timestamp,
            approvedTimestamp: 0,
            executedTimestamp: 0,
            executionResult: "",
            state: ProposalState.Pending,
            yesVotes: 0,
            noVotes: 0
        });

        emit ProposalCreated(proposalCount, msg.sender, _targetContract);
    }

    function vote(uint _proposalId, bool _voteYes)
        external
        onlyMember
        proposalExists(_proposalId)
        notVoted(_proposalId)
        inState(_proposalId, ProposalState.Pending)
    {
        Proposal storage proposal = proposals[_proposalId];

        if (block.timestamp > proposal.deadline) {
            proposal.state = ProposalState.Expired;
            emit ProposalStateChanged(_proposalId, ProposalState.Expired);
            revert("Proposal expired");
        }

        hasVoted[_proposalId][msg.sender] = true;
        memberVotes[_proposalId][msg.sender] = _voteYes;

        if (_voteYes) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit Voted(_proposalId, msg.sender, _voteYes);

        uint requiredQuorumVotes = (memberCount * quorumPercentage + 99) / 100; // ceil division
        uint totalVotes = proposal.yesVotes + proposal.noVotes;

        if (totalVotes >= requiredQuorumVotes && proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Approved;
            proposal.approvedTimestamp = block.timestamp;
            emit ProposalStateChanged(_proposalId, ProposalState.Approved);
        }
    }

    function execute(uint _proposalId)
        external
        onlyMember
        proposalExists(_proposalId)
        inState(_proposalId, ProposalState.Approved)
    {
        Proposal storage proposal = proposals[_proposalId];

        if (block.timestamp > proposal.deadline) {
            proposal.state = ProposalState.Expired;
            emit ProposalStateChanged(_proposalId, ProposalState.Expired);
            revert("Proposal expired");
        }

        uint execStart = proposal.approvedTimestamp + proposal.minExecutionDelay;
        require(block.timestamp >= execStart, "Execution delay not passed");

        bool success;
        bytes memory result;

        if (proposal.targetContract != address(0)) {
            (success, result) = proposal.targetContract.call{value: 0}(proposal.callData);
        } else {
            success = true;
        }

        proposal.executedTimestamp = block.timestamp;
        proposal.executionResult = result;

        if (success) {
            proposal.state = ProposalState.Executed;
            emit ProposalStateChanged(_proposalId, ProposalState.Executed);
        } else {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(_proposalId, ProposalState.Failed);
        }

        emit ProposalExecuted(_proposalId, success, result);
    }

    function getProposal(uint _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getVote(uint _proposalId, address _voter) external view proposalExists(_proposalId) returns (bool voted, bool voteChoice) {
        require(isMember[_voter], "Not a member");
        voted = hasVoted[_proposalId][_voter];
        voteChoice = voted ? memberVotes[_proposalId][_voter] : false;
    }
}
