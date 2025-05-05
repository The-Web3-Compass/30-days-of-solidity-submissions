// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedGovernance
 * @author shivam
 * @notice A contract for managing members, proposals, voting, and execution of approved proposals targeting other contracts.
 * @dev - Owner manages membership.
 *      - Members create proposals and vote.
 *      - Proposals require a quorum (50%) and majority to pass.
 *      - Execution is time-locked and results are stored.
 */
contract DecentralizedGovernance {
    /// @notice The address of the contract owner
    address public owner;

    /// @notice The total number of proposals created
    uint public proposalCount;

    /// @notice The total number of active members
    uint public memberCount;

    /// @notice The percentage of total members required for a quorum (e.g., 50 for 50%)
    uint public quorumPercentage;

    /// @notice Mapping to track if an address is a member
    mapping(address => bool) public isMember;

    /// @notice Mapping from proposal ID to Proposal struct
    mapping(uint => Proposal) public proposals;

    /// @notice Mapping to track if a member has voted on a specific proposal
    mapping(uint => mapping(address => bool)) public hasVoted;

    /// @notice Mapping to track the actual vote of a member on a proposal (true=yes, false=no)
    mapping(uint => mapping(address => bool)) public memberVotes;

    // --- Enums & Structs ---

    /// @notice Represents the current state of a proposal.
    enum ProposalState {
        // Proposal is open for voting
        Pending,
        // Quorum and majority reached, waiting for execution window
        Approved,
        // Successfully executed
        Executed,
        // Execution attempted but failed
        Failed,
        // Execution window passed without execution
        Expired
    }

    /// @notice Represents a proposal in the governance system.
    struct Proposal {
        /// @notice The unique identifier of the proposal
        uint id;
        /// @notice The address of the member who created the proposal
        address proposer;
        /// @notice A description of the proposal
        string description;
        /// @notice The address of the target contract to call if the proposal is approved. address(0) if no contract call.
        address targetContract;
        /// @notice The data to send in the external call. Empty bytes if no contract call.
        bytes callData;
        /// @notice The minimum time in seconds after approval before execution is allowed
        uint minExecutionDelay;
        /// @notice The timestamp after which the proposal expires and no action (voting or execution) is allowed.
        uint deadline;
        /// @notice The timestamp when the proposal was created
        uint createdTimestamp;
        /// @notice The timestamp when quorum and majority were met
        uint approvedTimestamp;
        /// @notice The timestamp when the proposal was executed
        uint executedTimestamp;
        /// @notice The return data from the external call
        bytes executionResult;
        /// @notice The current state of the proposal
        ProposalState state;
        /// @notice The number of 'yes' votes
        uint yesVotes;
        /// @notice The number of 'no' votes
        uint noVotes;
    }

    // --- Events ---

    /// @notice Emitted when a new member is added to the governance system.
    /// @param member The address of the member added.
    event MemberAdded(address indexed member);

    /// @notice Emitted when a member is removed from the governance system.
    /// @param member The address of the member removed.
    event MemberRemoved(address indexed member);

    /// @notice Emitted when a new proposal is created.
    /// @param proposalId The unique ID of the created proposal.
    /// @param proposer The address of the member who created the proposal.
    /// @param targetContract The address of the target contract for the proposal.
    event ProposalCreated(
        uint indexed proposalId,
        address indexed proposer,
        address targetContract
    );

    /// @notice Emitted when a member casts a vote on a proposal.
    /// @param proposalId The ID of the proposal voted on.
    /// @param voter The address of the member who voted.
    /// @param voteYes True if the vote was 'yes', false if 'no'.
    event Voted(uint indexed proposalId, address indexed voter, bool voteYes);

    /// @notice Emitted when the state of a proposal changes.
    /// @param proposalId The ID of the proposal whose state changed.
    /// @param newState The new state of the proposal.
    event ProposalStateChanged(uint indexed proposalId, ProposalState newState);

    /// @notice Emitted after an attempt to execute an approved proposal.
    /// @param proposalId The ID of the proposal that was executed.
    /// @param success True if the execution was successful, false otherwise.
    /// @param result The return data from the external call.
    event ProposalExecuted(uint indexed proposalId, bool success, bytes result);

    /// @notice Emitted when the quorum percentage is updated.
    /// @param newQuorumPercentage The new quorum percentage.
    event QuorumUpdated(uint newQuorumPercentage);

    // --- Modifiers ---

    /// @dev Modifier to restrict function calls to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Governance: Caller is not the owner");
        _;
    }

    /// @dev Modifier to restrict function calls to members of the governance system.
    modifier onlyMember() {
        require(isMember[msg.sender], "Governance: Caller is not a member");
        _;
    }

    /// @dev Modifier to check if a proposal with the given ID exists.
    /// @param _proposalId The ID of the proposal to check.
    modifier proposalExists(uint _proposalId) {
        require(
            _proposalId > 0 && _proposalId <= proposalCount,
            "Governance: Proposal does not exist"
        );
        _;
    }

    /// @dev Modifier to check if the caller has already voted on a specific proposal.
    /// @param _proposalId The ID of the proposal to check.
    modifier notVoted(uint _proposalId) {
        require(
            !hasVoted[_proposalId][msg.sender],
            "Governance: Member already voted"
        );
        _;
    }

    /// @dev Modifier to check if a proposal is in a specific state.
    /// @param _proposalId The ID of the proposal to check.
    /// @param _state The required state of the proposal.
    modifier inState(uint _proposalId, ProposalState _state) {
        require(
            proposals[_proposalId].state == _state,
            "Governance: Proposal not in required state"
        );
        _;
    }

    // --- Constructor ---

    /**
     * @notice Initializes the contract.
     * @param _initialQuorumPercentage The initial percentage of total members required for a quorum (1-100).
     */
    constructor(uint _initialQuorumPercentage) {
        require(
            _initialQuorumPercentage > 0 && _initialQuorumPercentage <= 100,
            "Governance: Quorum must be between 1 and 100"
        );

        owner = msg.sender;
        quorumPercentage = _initialQuorumPercentage;

        // Add the owner as the first member
        isMember[owner] = true;
        memberCount = 1;

        emit MemberAdded(owner);
        emit QuorumUpdated(_initialQuorumPercentage);
    }

    // --- Governance Settings ---

    /**
     * @notice Adds a new member to the governance system.
     * @dev Can only be called by the owner. Emits {MemberAdded}.
     * @param _member The address of the member to add.
     */
    function addMember(address _member) external onlyOwner {
        require(_member != address(0), "Governance: Cannot add zero address");
        require(!isMember[_member], "Governance: Address is already a member");
        isMember[_member] = true;
        memberCount++;
        emit MemberAdded(_member);
    }

    /**
     * @notice Removes an existing member from the governance system.
     * @dev Can only be called by the owner. Emits {MemberRemoved}.
     *      Removing members can affect quorum calculations for active proposals.
     * @param _member The address of the member to remove.
     */
    function removeMember(address _member) external onlyOwner {
        require(
            _member != address(0),
            "Governance: Cannot remove zero address"
        );
        require(isMember[_member], "Governance: Address is not a member");
        require(_member != owner, "Governance: Cannot remove the owner");
        isMember[_member] = false;
        memberCount--;
        emit MemberRemoved(_member);
    }

    /**
     * @notice Updates the quorum percentage required for proposals to pass.
     * @dev Can only be called by the owner. Emits {QuorumUpdated}.
     * @param _newQuorumPercentage The new quorum percentage (1-100).
     */
    function updateQuorum(uint _newQuorumPercentage) external onlyOwner {
        require(
            _newQuorumPercentage > 0 && _newQuorumPercentage <= 100,
            "Governance: Quorum must be between 1 and 100"
        );
        quorumPercentage = _newQuorumPercentage;
        emit QuorumUpdated(_newQuorumPercentage);
    }

    // --- Proposal Creation ---

    /**
     * @notice Creates a new proposal.
     * @dev Can only be called by a member.
     * @param _description A description of the proposal.
     * @param _targetContract The address of the contract to call if approved. Use address(0) if no contract call.
     * @param _callData The data to use in the external call. Use "" (empty bytes) if no contract call.
     * @param _minExecutionDelay Seconds after approval before execution is allowed.
     * @param _deadline The timestamp after which the proposal expires.
     */
    function createProposal(
        string memory _description,
        address _targetContract,
        bytes memory _callData,
        uint _minExecutionDelay,
        uint _deadline
    ) external onlyMember {
        require(
            bytes(_description).length > 0,
            "Governance: Description cannot be empty"
        );
        if (_targetContract != address(0)) {
            require(
                _callData.length > 0,
                "Governance: Call data required for target contract"
            );
        } else {
            require(
                _callData.length == 0,
                "Governance: Call data must be empty if no target contract"
            );
        }
        require(
            _deadline > block.timestamp,
            "Governance: Deadline must be in the future"
        );
        // Note: minExecutionDelay is relative to approval time, deadline is absolute timestamp.
        // We don't need to check _deadline > _minExecutionDelay here.

        proposalCount++;
        uint newProposalId = proposalCount;

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            minExecutionDelay: _minExecutionDelay,
            deadline: _deadline,
            createdTimestamp: block.timestamp,
            approvedTimestamp: 0,
            executedTimestamp: 0,
            executionResult: "", // Empty bytes initially
            state: ProposalState.Pending,
            yesVotes: 0,
            noVotes: 0
        });

        emit ProposalCreated(newProposalId, msg.sender, _targetContract);
    }

    // --- Voting & Execution ---

    /**
     * @notice Cast a vote on a pending proposal.
     * @dev Can only be called by a member who hasn't voted on this proposal yet.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _voteYes True for a 'yes' vote, false for a 'no' vote.
     */
    function vote(
        uint _proposalId,
        bool _voteYes
    )
        external
        onlyMember
        proposalExists(_proposalId)
        notVoted(_proposalId)
        inState(_proposalId, ProposalState.Pending)
    {
        Proposal storage proposal = proposals[_proposalId];

        // Check if the proposal has expired
        if (block.timestamp > proposal.deadline) {
            proposal.state = ProposalState.Expired;
            emit ProposalStateChanged(_proposalId, ProposalState.Expired);
            revert("Governance: Proposal has expired");
        }

        // Record the vote
        hasVoted[_proposalId][msg.sender] = true;
        memberVotes[_proposalId][msg.sender] = _voteYes;

        if (_voteYes) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit Voted(_proposalId, msg.sender, _voteYes);

        // Check if quorum and majority are met
        // Note: Quorum calculation uses memberCount at the time of the vote.
        // This means members added/removed after voting starts affect the threshold.
        uint requiredQuorumVotes = (memberCount * quorumPercentage) / 100;

        // Handle potential rounding if memberCount * quorumPercentage is not divisible by 100
        if ((memberCount * quorumPercentage) % 100 != 0) {
            requiredQuorumVotes++; // Need at least this many votes
        }

        uint totalVotes = proposal.yesVotes + proposal.noVotes;

        if (
            totalVotes >= requiredQuorumVotes &&
            proposal.yesVotes > proposal.noVotes
        ) {
            proposal.state = ProposalState.Approved;
            proposal.approvedTimestamp = block.timestamp;
            emit ProposalStateChanged(_proposalId, ProposalState.Approved);
        }
        // If quorum is met but it's a tie or 'no' wins, it remains Pending until potentially more votes shift the balance.
        // A proposal cannot fail just by votes, only by expiration or failed execution.
    }

    /**
     * @notice Executes an approved proposal.
     * @dev Can be called by any member if the proposal is Approved and within its execution window.
     * @param _proposalId The ID of the proposal to execute.
     */
    function execute(
        uint _proposalId
    )
        external
        onlyMember
        proposalExists(_proposalId)
        inState(_proposalId, ProposalState.Approved)
    {
        Proposal storage proposal = proposals[_proposalId];

        // Check if the proposal has expired
        if (block.timestamp > proposal.deadline) {
            proposal.state = ProposalState.Expired;
            emit ProposalStateChanged(_proposalId, ProposalState.Expired);
            revert("Governance: Proposal has expired");
        }

        uint executionWindowStart = proposal.approvedTimestamp +
            proposal.minExecutionDelay;

        // Check if execution delay has passed
        if (block.timestamp < executionWindowStart) {
            revert("Governance: Minimum execution delay has not passed");
        }

        // Perform the external call if a target is specified
        bool success;
        bytes memory result = "";

        if (proposal.targetContract != address(0)) {
            (success, result) = proposal.targetContract.call{value: 0}(
                proposal.callData
            );
        } else {
            // If no target contract, the proposal is considered successfully "executed"
            // as its purpose might be signaling or off-chain action coordination.
            success = true;
        }

        // Update state based on execution result
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

    // --- Getters ---

    /**
     * @notice Retrieves the details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A Proposal struct containing all details.
     */
    function getProposal(
        uint _proposalId
    ) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @notice Checks if a member has voted on a proposal and what their vote was.
     * @param _proposalId The ID of the proposal.
     * @param _voter The address of the member.
     * @return voted True if the member has voted, false otherwise.
     * @return voteChoice True if the vote was 'yes', false if 'no'. Only valid if voted is true.
     */
    function getVote(
        uint _proposalId,
        address _voter
    )
        external
        view
        proposalExists(_proposalId)
        returns (bool voted, bool voteChoice)
    {
        require(isMember[_voter], "Governance: Address is not a member");
        voted = hasVoted[_proposalId][_voter];
        if (voted) {
            voteChoice = memberVotes[_proposalId][_voter];
        } else {
            voteChoice = false; // Default value if not voted
        }
    }
}
