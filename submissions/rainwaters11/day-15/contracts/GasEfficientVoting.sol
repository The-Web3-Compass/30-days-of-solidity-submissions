// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasEfficientVoting {
	uint256 public constant MAX_PROPOSALS = 256;

	struct Proposal {
		bytes32 descriptionHash;
		uint32 yesVotes;
		uint32 noVotes;
		uint32 deadline;
		bool isActive;
	}

	Proposal[] private proposals;

	// Each voter stores a 256-bit map where bit N means they voted on proposal N.
	mapping(address => uint256) public voterRegistry;

	error InvalidProposal();
	error VotingClosed();
	error AlreadyVoted();
	error MaxProposalsReached();
	error InvalidDuration();
	error TimestampOverflow();

	event ProposalCreated(uint256 indexed proposalId, bytes32 indexed descriptionHash, uint32 deadline);
	event Voted(uint256 indexed proposalId, address indexed voter, bool support);
	event ProposalClosed(uint256 indexed proposalId);

	function createProposal(bytes32 descriptionHash, uint32 durationSeconds) external returns (uint256 proposalId) {
		if (durationSeconds == 0) revert InvalidDuration();

		proposalId = proposals.length;
		if (proposalId >= MAX_PROPOSALS) revert MaxProposalsReached();

		uint256 nowTs = block.timestamp;
		uint256 deadlineTs = nowTs + durationSeconds;
		if (deadlineTs > type(uint32).max) revert TimestampOverflow();

		proposals.push(
			Proposal({
				descriptionHash: descriptionHash,
				yesVotes: 0,
				noVotes: 0,
				deadline: uint32(deadlineTs),
				isActive: true
			})
		);

		emit ProposalCreated(proposalId, descriptionHash, uint32(deadlineTs));
	}

	function vote(uint256 proposalId, bool support) external {
		if (proposalId >= proposals.length) revert InvalidProposal();

		Proposal storage proposal = proposals[proposalId];
		if (!proposal.isActive || block.timestamp > proposal.deadline) revert VotingClosed();

		uint256 mask = 1 << proposalId;
		uint256 currentBitmap = voterRegistry[msg.sender];
		if (currentBitmap & mask != 0) revert AlreadyVoted();

		voterRegistry[msg.sender] = currentBitmap | mask;

		if (support) {
			unchecked {
				proposal.yesVotes++;
			}
		} else {
			unchecked {
				proposal.noVotes++;
			}
		}

		emit Voted(proposalId, msg.sender, support);
	}

	function closeProposal(uint256 proposalId) external {
		if (proposalId >= proposals.length) revert InvalidProposal();

		Proposal storage proposal = proposals[proposalId];
		if (!proposal.isActive || block.timestamp <= proposal.deadline) revert VotingClosed();

		proposal.isActive = false;
		emit ProposalClosed(proposalId);
	}

	function hasVoted(address voter, uint256 proposalId) external view returns (bool) {
  if (proposalId >= proposals.length) revert InvalidProposal();

		uint256 mask = 1 << proposalId;
		return voterRegistry[voter] & mask != 0;
	}

	function getProposal(uint256 proposalId)
		external
		view
		returns (bytes32 descriptionHash, uint32 yesVotes, uint32 noVotes, uint32 deadline, bool isActive)
	{
		if (proposalId >= proposals.length) revert InvalidProposal();

		Proposal storage proposal = proposals[proposalId];
		return (
			proposal.descriptionHash,
			proposal.yesVotes,
			proposal.noVotes,
			proposal.deadline,
			proposal.isActive
		);
	}

	function proposalCount() external view returns (uint256) {
		return proposals.length;
	}
}
