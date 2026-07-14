// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasSaver {
   
    struct Proposal {
        uint64 proposalId;      
        uint64 voteCount;       
        uint64 againstCount;    
        uint64 abstainCount;    
        uint8 status;           
        uint40 endTime;         
        string title;           
        string description;     
    }
    

    struct Vote {
        uint8 choice;           
        uint40 timestamp;       
        uint32 weight;          
    }
    

    struct ContractState {
        address owner;          
        uint64 totalProposals;  
        uint32 votingPeriod;    
        bool paused;            
    }
    
    ContractState public state;
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Vote)) public votes; 
    mapping(address => bool) public hasVotingRights;
    mapping(address => uint256) public voterNonce;

    uint256[] public activeProposalIds;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed creator,
        string title,
        string description,
        uint256 endTime
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        uint8 indexed choice,
        uint32 weight,
        uint256 timestamp
    );
    
    event ProposalStatusChanged(uint256 indexed proposalId, uint8 newStatus);

    error NotOwner();
    error ProposalNotFound();
    error VotingEnded();
    error AlreadyVoted();
    error NoVotingRights();
    error ContractPaused();
    error InvalidChoice();
    error ZeroAddress();

    modifier onlyOwner() {
        if (msg.sender != state.owner) revert NotOwner();
        _;
    }
    
    modifier whenNotPaused() {
        if (state.paused) revert ContractPaused();
        _;
    }
    
    modifier hasVotingRight() {
        if (!hasVotingRights[msg.sender]) revert NoVotingRights();
        _;
    }

    constructor(uint32 _votingPeriod) {
        state.owner = msg.sender;
        state.votingPeriod = _votingPeriod;
        hasVotingRights[msg.sender] = true;
    }
    
    function createProposal(
        string calldata title,    
        string calldata description
    ) external onlyOwner whenNotPaused {
        if (bytes(title).length == 0) revert ProposalNotFound();
        
        uint256 proposalId = ++state.totalProposals;
        
        proposals[proposalId] = Proposal({
            proposalId: uint64(proposalId),
            voteCount: 0,
            againstCount: 0,
            abstainCount: 0,
            status: 0, 
            endTime: uint40(block.timestamp + state.votingPeriod),
            title: title,
            description: description
        });
        
        activeProposalIds.push(proposalId);
        
        emit ProposalCreated(proposalId, msg.sender, title, description, block.timestamp + state.votingPeriod);
    }
    
    
    function vote(uint256 proposalId, uint8 choice) external hasVotingRight whenNotPaused {
        if (choice > 2) revert InvalidChoice();
        if (votes[proposalId][msg.sender].timestamp != 0) revert AlreadyVoted();
        
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalId == 0) revert ProposalNotFound();
        if (block.timestamp >= proposal.endTime) revert VotingEnded();
        
        uint32 weight = _calculateVotingWeight(msg.sender);
        
        votes[proposalId][msg.sender] = Vote({
            choice: choice,
            timestamp: uint40(block.timestamp),
            weight: weight
        });
        
        if (choice == 0) {
            proposal.voteCount += weight;
        } else if (choice == 1) {
            proposal.againstCount += weight;
        } else {
            proposal.abstainCount += weight;
        }
        
        ++voterNonce[msg.sender];
        
        emit VoteCast(proposalId, msg.sender, choice, weight, block.timestamp);
    }
    

    function batchVote(
        uint256[] calldata proposalIds,
        uint8[] calldata choices
    ) external hasVotingRight whenNotPaused {
        if (proposalIds.length != choices.length) revert ProposalNotFound();
        
        uint256 length = proposalIds.length;
        uint32 weight = _calculateVotingWeight(msg.sender);
        
        uint40 currentTime = uint40(block.timestamp);
        
        for (uint256 i; i < length; ) {
            uint256 propId = proposalIds[i];
            uint8 choice = choices[i];

            if (choice > 2) revert InvalidChoice();
            if (votes[propId][msg.sender].timestamp != 0) revert AlreadyVoted();
            
            Proposal storage proposal = proposals[propId];
            if (proposal.proposalId == 0) revert ProposalNotFound();
            if (currentTime >= proposal.endTime) revert VotingEnded();
            
            votes[propId][msg.sender] = Vote({
                choice: choice,
                timestamp: currentTime,
                weight: weight
            });
            
            if (choice == 0) {
                proposal.voteCount += weight;
            } else if (choice == 1) {
                proposal.againstCount += weight;
            } else {
                proposal.abstainCount += weight;
            }
            
            emit VoteCast(propId, msg.sender, choice, weight, currentTime);
            
            unchecked { ++i; } 
        }
        
        voterNonce[msg.sender] += length;
    }
    
    function getProposalResults(uint256 proposalId) external view returns (
        uint64 forVotes,
        uint64 againstVotes,
        uint64 abstainVotes,
        uint8 status,
        bool ended
    ) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalId == 0) revert ProposalNotFound();
        
        return (
            proposal.voteCount,
            proposal.againstCount,
            proposal.abstainCount,
            proposal.status,
            block.timestamp >= proposal.endTime
        );
    }

    function canVote(address user, uint256 proposalId) external view returns (bool) {
        return 
            hasVotingRights[user] && 
            !state.paused && 
            votes[proposalId][user].timestamp == 0 &&
            proposals[proposalId].proposalId != 0 &&
            block.timestamp < proposals[proposalId].endTime;
    }
    


    function _calculateVotingWeight(address /* voter */) internal pure returns (uint32) {
        return 1;
    }

    

    function finalizeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalId == 0) revert ProposalNotFound();
        if (block.timestamp < proposal.endTime) revert VotingEnded();
        if (proposal.status != 0) return; 
        
        uint8 newStatus;
        if (proposal.voteCount > proposal.againstCount) {
            newStatus = 1; 
        } else {
            newStatus = 2; 
        }
        
        proposal.status = newStatus;
        _removeFromActiveProposals(proposalId);
        
        emit ProposalStatusChanged(proposalId, newStatus);
    }
    
    function _removeFromActiveProposals(uint256 proposalId) internal {
        uint256 length = activeProposalIds.length;
        for (uint256 i; i < length; ) {
            if (activeProposalIds[i] == proposalId) {
                activeProposalIds[i] = activeProposalIds[length - 1];
                activeProposalIds.pop();
                break;
            }
            unchecked { ++i; }
        }
    }
    

    function grantVotingRights(address[] calldata users) external onlyOwner {
        uint256 length = users.length;
        for (uint256 i; i < length; ) {
            address user = users[i];
            if (user == address(0)) revert ZeroAddress();
            hasVotingRights[user] = true;
            unchecked { ++i; }
        }
    }
    

    function revokeVotingRights(address[] calldata users) external onlyOwner {
        uint256 length = users.length;
        for (uint256 i; i < length; ) {
            hasVotingRights[users[i]] = false;
            unchecked { ++i; }
        }
    }

    function setPaused(bool _paused) external onlyOwner {
        state.paused = _paused;
    }
    

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        state.owner = newOwner;
    }
    

    function getActiveProposalsCount() external view returns (uint256) {
        return activeProposalIds.length;
    }

    function getContractState() external view returns (
        address owner,
        uint64 totalProposals,
        uint32 votingPeriod,
        bool paused,
        uint256 activeCount
    ) {
        return (
            state.owner,
            state.totalProposals,
            state.votingPeriod,
            state.paused,
            activeProposalIds.length
        );
    }

    function getUserVotingInfo(address user) external view returns (
        bool canVoteGeneral,
        uint256 nonce
    ) {
        return (
            hasVotingRights[user] && !state.paused,
            voterNonce[user]
        );
    }
}
