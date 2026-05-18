// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title  DecentralizedGovernance — "Misty DAO"
/// @author rainwaters11 — Day 28: Distributed Democracy
/// @notice On-chain governance for MistyCoin-Core.  $WATERS holders can
///         propose, debate, and execute changes to any protocol contract —
///         replacing single-owner `Ownable` with community rule.
///
/// @dev    DAO LIFECYCLE (the five-step process):
///         ┌──────────────────────────────────────────────────────────────┐
///         │ 1. STAKE    — Hold $WATERS to have a voice.                  │
///         │ 2. PROPOSE  — Lock PROPOSAL_DEPOSIT to create a proposal.    │
///         │ 3. DEBATE   — Community votes during VOTING_PERIOD (3 days). │
///         │ 4. QUORUM   — ≥ QUORUM_PERCENT% of supply must participate.  │
///         │ 5. TIMELOCK — Passed proposals wait TIMELOCK_PERIOD (2 days) │
///         │               before execution (defence vs governance attacks)│
///         └──────────────────────────────────────────────────────────────┘
///
///         VOTE WEIGHTING
///         Each voter's weight = their $WATERS balanceOf at the time of the
///         vote call.  This is deliberately simple for Day 28.
///
///         ⚠️  FLASH LOAN NOTE (for senior dev interviews)
///         A production DAO records a snapshot of every address's balance at
///         the block the proposal was created (see ERC20Votes / EIP-5805).
///         Without a snapshot, an attacker could borrow tokens via a flash
///         loan, vote, and return them in the same transaction.  We keep it
///         simple here but the architecture is easy to upgrade: replace
///         `IERC20(_token).balanceOf(voter)` with
///         `IVotes(_token).getPastVotes(voter, proposal.snapshotBlock)`.
///
///         $WATERS REAL-WORLD VOTES
///         • "Increase Crochet Chain Stitch rewards?"
///         • "Change the CropInsurance premium?"
///         • "Add a new DEX pair to MiniDexFactory?"
contract DecentralizedGovernance is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ─── Types ────────────────────────────────────────────────────────────────

    /// @notice All states a proposal can be in throughout its lifecycle.
    enum ProposalState {
        Active,     // Voting window is open.
        Passed,     // Voting ended; quorum met; yes > no.  Waiting for timelock.
        Failed,     // Voting ended; quorum not met OR no >= yes.
        Executed,   // Proposal executed on-chain after timelock.
        Cancelled   // Creator cancelled before voting ended.
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string  description;
        // On-chain execution payload.
        address target;         // Contract to call.
        bytes   callData;       // Encoded function call.
        // Timing.
        uint256 createdAt;      // block.timestamp when proposal was created.
        uint256 votingDeadline; // createdAt + VOTING_PERIOD.
        uint256 executableAt;   // votingDeadline + TIMELOCK_PERIOD (set on finalize).
        // Vote tallies (weighted by $WATERS balance).
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVoters;    // unique addresses that voted.
        // State.
        ProposalState state;
        // Deposit (returned to proposer on success or after failure).
        uint256 deposit;
    }

    // ─── Constants ────────────────────────────────────────────────────────────

    /// @notice Tokens required to create a proposal (spam protection).
    ///         100 $WATERS (18 decimals).
    uint256 public constant PROPOSAL_DEPOSIT = 100 * 1e18;

    /// @notice How long the community can vote after a proposal is created.
    uint256 public constant VOTING_PERIOD = 3 days;

    /// @notice Mandatory delay between a proposal passing and being executable.
    ///         Gives the community time to react to a "governance attack."
    uint256 public constant TIMELOCK_PERIOD = 2 days;

    /// @notice Minimum participation required for a proposal to be valid.
    ///         4 % of the token's totalSupply (weighted votes) must be cast.
    uint256 public constant QUORUM_PERCENT = 4;

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice The governance / voting token ($WATERS).
    IERC20 public immutable governanceToken;

    /// @notice Sequential proposal counter.
    uint256 public proposalCount;

    /// @dev proposalId → Proposal.
    mapping(uint256 => Proposal) private _proposals;

    /// @dev proposalId → voter → hasVoted.
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // ─── Events ───────────────────────────────────────────────────────────────

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string  description,
        uint256 votingDeadline
    );

    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool    support,
        uint256 weight      // balanceOf at vote time
    );

    event ProposalFinalized(
        uint256 indexed proposalId,
        ProposalState   result,
        uint256         yesVotes,
        uint256         noVotes
    );

    event ProposalExecuted(uint256 indexed proposalId, address target);

    event ProposalCancelled(uint256 indexed proposalId);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error InsufficientDeposit();
    error InsufficientTokenBalance();   // proposer has fewer tokens than deposit
    error VotingClosed();               // voting period has ended
    error VotingStillOpen();            // trying to finalize too early
    error AlreadyVoted();
    error NoVotingPower();              // caller holds zero $WATERS
    error ProposalNotPassed();          // trying to execute a non-Passed proposal
    error TimelockNotExpired();         // timelock still running
    error ExecutionFailed();            // target.call returned false
    error ProposalNotActive();          // can only cancel Active proposals
    error NotProposer();                // only proposer can cancel

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @param _governanceToken  Address of the $WATERS ERC-20 contract.
    constructor(address _governanceToken) {
        require(_governanceToken != address(0), "Gov: zero token address");
        governanceToken = IERC20(_governanceToken);
    }

    // ─── 1. CREATE PROPOSAL ───────────────────────────────────────────────────

    /// @notice Submit a new governance proposal.
    ///
    /// @dev    SPAM PROTECTION — caller must approve and lock PROPOSAL_DEPOSIT
    ///         (100 $WATERS) before calling.  The deposit is refunded when the
    ///         proposal is executed or cancelled, or forfeited on failure.
    ///
    ///         PRACTICAL EXAMPLES FOR $WATERS HOLDERS:
    ///         • description = "Increase crochet stitch reward from 10 to 15 WATERS"
    ///         • description = "Change CropInsurance premium from 5% to 3%"
    ///
    /// @param description  Human-readable summary of the change being proposed.
    /// @param target       Contract address that will be called on execution.
    /// @param callData     ABI-encoded function call to run on `target`.
    /// @return proposalId  ID of the newly created proposal.
    function createProposal(
        string calldata description,
        address target,
        bytes   calldata callData
    ) external nonReentrant returns (uint256 proposalId) {
        // Proposer must hold at least the deposit amount.
        if (governanceToken.balanceOf(msg.sender) < PROPOSAL_DEPOSIT)
            revert InsufficientTokenBalance();

        // Pull the deposit from the proposer.
        governanceToken.safeTransferFrom(msg.sender, address(this), PROPOSAL_DEPOSIT);

        proposalId = ++proposalCount;

        _proposals[proposalId] = Proposal({
            id:             proposalId,
            proposer:       msg.sender,
            description:    description,
            target:         target,
            callData:       callData,
            createdAt:      block.timestamp,
            votingDeadline: block.timestamp + VOTING_PERIOD,
            executableAt:   0,              // set inside finalize()
            yesVotes:       0,
            noVotes:        0,
            totalVoters:    0,
            state:          ProposalState.Active,
            deposit:        PROPOSAL_DEPOSIT
        });

        emit ProposalCreated(
            proposalId,
            msg.sender,
            description,
            block.timestamp + VOTING_PERIOD
        );
    }

    // ─── 2. VOTE ──────────────────────────────────────────────────────────────

    /// @notice Cast a weighted vote on an Active proposal.
    ///
    /// @dev    VOTE WEIGHT = balanceOf(voter) at the moment of this call.
    ///         One address may only vote once per proposal.
    ///
    ///         ⚠️  FLASH LOAN VECTOR (educational note)
    ///         An attacker with a flash loan could borrow tokens, call vote(),
    ///         and return the tokens in the same tx.  A production system should
    ///         use ERC20Votes.getPastVotes(voter, proposal.snapshotBlock) here.
    ///         For Day 28 we keep it simple and use a live balanceOf check.
    ///
    /// @param proposalId  Which proposal to vote on.
    /// @param support     true = YES (for the proposal), false = NO (against).
    function vote(uint256 proposalId, bool support) external nonReentrant {
        Proposal storage p = _proposals[proposalId];

        // Guard: must be in Active state and within the voting window.
        if (p.state != ProposalState.Active)   revert VotingClosed();
        if (block.timestamp > p.votingDeadline) revert VotingClosed();
        if (hasVoted[proposalId][msg.sender])   revert AlreadyVoted();

        // ── Determine vote weight from $WATERS balance ─────────────────────────
        //    Each token = 1 unit of voting power (1 token = 1 vote).
        uint256 weight = governanceToken.balanceOf(msg.sender);
        if (weight == 0) revert NoVotingPower();

        // ── Record the vote ───────────────────────────────────────────────────
        hasVoted[proposalId][msg.sender] = true;
        p.totalVoters++;

        if (support) {
            p.yesVotes += weight;
        } else {
            p.noVotes  += weight;
        }

        emit VoteCast(proposalId, msg.sender, support, weight);
    }

    // ─── 3. FINALIZE ──────────────────────────────────────────────────────────

    /// @notice Tally the result once the voting window has closed.
    ///         Transitions the proposal to Passed or Failed.
    ///         If Passed, starts the TIMELOCK_PERIOD clock.
    ///
    /// @dev    QUORUM CHECK
    ///         totalWeightedVotes ≥ QUORUM_PERCENT% of token totalSupply.
    ///         E.g. if 1,000,000 WATERS exist, at least 40,000 must have voted.
    ///
    ///         ON PASS — the proposer's deposit is kept in escrow until execute().
    ///         ON FAIL — the deposit is forfeited to the contract (spam deterrent).
    ///
    /// @param proposalId  Proposal to finalize.
    function finalize(uint256 proposalId) external nonReentrant {
        Proposal storage p = _proposals[proposalId];

        if (p.state != ProposalState.Active)     revert VotingClosed();
        if (block.timestamp <= p.votingDeadline) revert VotingStillOpen();

        uint256 totalWeightedVotes = p.yesVotes + p.noVotes;
        uint256 quorumThreshold    =
            (governanceToken.totalSupply() * QUORUM_PERCENT) / 100;

        bool quorumMet  = totalWeightedVotes >= quorumThreshold;
        bool majorityYes = p.yesVotes > p.noVotes;

        if (quorumMet && majorityYes) {
            // ── PASSED ────────────────────────────────────────────────────────
            p.state        = ProposalState.Passed;
            p.executableAt = block.timestamp + TIMELOCK_PERIOD;
        } else {
            // ── FAILED ────────────────────────────────────────────────────────
            p.state = ProposalState.Failed;
            // Forfeit the deposit — leaves it locked in this contract as a
            // deterrent against low-effort or malicious proposals.
        }

        emit ProposalFinalized(proposalId, p.state, p.yesVotes, p.noVotes);
    }

    // ─── 4. EXECUTE ───────────────────────────────────────────────────────────

    /// @notice Execute a Passed proposal after its timelock has expired.
    ///
    /// @dev    THE TIMELOCK: even after a vote passes, execution is delayed by
    ///         TIMELOCK_PERIOD (2 days).  This is the community's "panic button"
    ///         window — if voters realise a proposal was a governance attack,
    ///         they have 2 days to coordinate a response (e.g., forking, removing
    ///         liquidity) before the malicious code can run.
    ///
    ///         EXECUTION: calls `target.call(callData)` and reverts if it fails.
    ///         The proposer's deposit is returned on successful execution.
    ///
    /// @param proposalId  Proposal to execute.
    function execute(uint256 proposalId) external nonReentrant {
        Proposal storage p = _proposals[proposalId];

        if (p.state != ProposalState.Passed) revert ProposalNotPassed();
        if (block.timestamp < p.executableAt) revert TimelockNotExpired();

        // Mark executed BEFORE the external call (checks-effects-interactions).
        p.state = ProposalState.Executed;

        // Return the proposer's deposit — they succeeded.
        address proposer = p.proposer;
        uint256 deposit  = p.deposit;
        p.deposit = 0;
        governanceToken.safeTransfer(proposer, deposit);

        // ── Execute the on-chain action ───────────────────────────────────────
        (bool success, ) = p.target.call(p.callData);
        if (!success) revert ExecutionFailed();

        emit ProposalExecuted(proposalId, p.target);
    }

    // ─── 5. CANCEL ────────────────────────────────────────────────────────────

    /// @notice Allow the proposer to cancel their own proposal while it is
    ///         still in the Active state.  Deposit is returned on cancellation.
    ///
    /// @param proposalId  Proposal to cancel.
    function cancelProposal(uint256 proposalId) external nonReentrant {
        Proposal storage p = _proposals[proposalId];

        if (p.state != ProposalState.Active) revert ProposalNotActive();
        if (msg.sender != p.proposer)        revert NotProposer();

        p.state = ProposalState.Cancelled;

        // Refund the deposit.
        uint256 deposit = p.deposit;
        p.deposit = 0;
        governanceToken.safeTransfer(msg.sender, deposit);

        emit ProposalCancelled(proposalId);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Returns the full struct for a given proposal.
    function getProposal(uint256 proposalId)
        external
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    /// @notice Returns a summary of the current vote tallies.
    /// @return state       Current ProposalState.
    /// @return yesVotes    Total weighted YES votes cast.
    /// @return noVotes     Total weighted NO votes cast.
    /// @return totalVoters Number of unique addresses that voted.
    /// @return quorum      Minimum weighted votes needed for validity.
    function getVoteSummary(uint256 proposalId)
        external
        view
        returns (
            ProposalState state,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 totalVoters,
            uint256 quorum
        )
    {
        Proposal storage p = _proposals[proposalId];
        state       = p.state;
        yesVotes    = p.yesVotes;
        noVotes     = p.noVotes;
        totalVoters = p.totalVoters;
        quorum      = (governanceToken.totalSupply() * QUORUM_PERCENT) / 100;
    }

    /// @notice Returns the seconds remaining in the voting window (0 if closed).
    function timeRemaining(uint256 proposalId)
        external
        view
        returns (uint256)
    {
        Proposal storage p = _proposals[proposalId];
        if (block.timestamp >= p.votingDeadline) return 0;
        return p.votingDeadline - block.timestamp;
    }

    /// @notice Returns seconds until a Passed proposal can be executed (0 if ready).
    function timelockRemaining(uint256 proposalId)
        external
        view
        returns (uint256)
    {
        Proposal storage p = _proposals[proposalId];
        if (p.executableAt == 0 || block.timestamp >= p.executableAt) return 0;
        return p.executableAt - block.timestamp;
    }
}
