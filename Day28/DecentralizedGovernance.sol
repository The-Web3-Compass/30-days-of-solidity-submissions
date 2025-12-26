// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract DecentralizedGovernance {
    IERC20 public governanceToken;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCount;
        uint256 deadline;
        bool executed;
        bool passed;
        mapping(address => bool) voted;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 id, address proposer, string description, uint256 deadline);
    event Voted(uint256 proposalId, address voter, uint256 weight);
    event ProposalExecuted(uint256 proposalId, bool passed);

    constructor(address _tokenAddress) {
        governanceToken = IERC20(_tokenAddress);
    }

    function createProposal(string memory _description) external {
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.proposer = msg.sender;
        p.description = _description;
        p.deadline = block.timestamp + 3 days;
        emit ProposalCreated(proposalCount, msg.sender, _description, p.deadline);
    }

    function vote(uint256 _proposalId) external {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.deadline, "Voting ended");
        require(!p.voted[msg.sender], "Voted");
        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No power");
        p.voted[msg.sender] = true;
        p.voteCount += weight;
        emit Voted(_proposalId, msg.sender, weight);
    }

    function executeProposal(uint256 _proposalId) external {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp >= p.deadline, "Not ended");
        require(!p.executed, "Executed");
        p.executed = true;
        if (p.voteCount > 100 ether) p.passed = true;
        emit ProposalExecuted(_proposalId, p.passed);
    }

    function getProposal(uint256 _id)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            uint256 voteCount,
            uint256 deadline,
            bool executed,
            bool passed
        )
    {
        Proposal storage p = proposals[_id];
        return (p.id, p.proposer, p.description, p.voteCount, p.deadline, p.executed, p.passed);
    }
}
