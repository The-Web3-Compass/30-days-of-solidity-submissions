
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title MinimalTokenBasedDAO
 * @author Eric (https://github.com/0xxEric)
 * @notice Minimal governance contract implementing token-based voting with per-proposal snapshot.
 * @dev This contract expects the governance token to implement the ERC20Votes-like interface:
 *      - getPastVotes(address account, uint256 blockNumber) => uint256
 *      - getPastTotalSupply(uint256 blockNumber) => uint256
 *
 * Typical workflow:
 * 1) A user creates a proposal (proposal snapshot block is recorded).
 * 2) After votingDelay blocks, voting opens for votingPeriod blocks.
 * 3) Token holders call vote(proposalId, support) during the voting window.
 *    Voting power for each voter is read from token.getPastVotes(voter, snapshotBlock).
 * 4) After the voting window ends, anyone can call finalizeProposal to compute result.
 * 5) If passed, anyone can call executeProposal to run the single call (target, value, calldata).
 *
 * WARNING: For production, combine with a Timelock and multi-call execution pattern.
 */



interface IERC20VotesLike {
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);
}

contract MinimalTokenBasedDAO {
    IERC20VotesLike public immutable governanceToken;
    address public admin; // privileged deployer/admin (can be governance-controlled in upgrades)

    uint256 public votingDelay;   // blocks after proposal creation before voting starts
    uint256 public votingPeriod;  // number of blocks voting remains open
    uint256 public quorumBps;     // quorum as basis points of total supply at snapshot (e.g., 400 => 4%)

    uint256 public proposalCount;

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        address target;      // single target contract to call if executed
        uint256 value;       // ETH value to send with call
        bytes callData;      // calldata to execute if proposal passes
        uint256 snapshotBlock; // block number used for voting power snapshot
        uint256 startBlock;  // voting starts at this block
        uint256 endBlock;    // voting ends at this block
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool finalized;     // whether voting result has been finalized
        bool canceled;
    }

    // receipt: records a voter's participation on a proposal
    struct Receipt {
        bool hasVoted;
        bool support;     // true = for, false = against
        uint256 votes;    // voting power used (snapshot)
    }

    // proposal storage
    mapping(uint256 => Proposal) public proposals;
    // per-proposal per-voter receipt
    mapping(uint256 => mapping(address => Receipt)) public receipts;

    // events
    event ProposalCreated(uint256 indexed id, address proposer, uint256 startBlock, uint256 endBlock);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalFinalized(uint256 indexed proposalId, bool passed);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor, bool success);
    event ProposalCanceled(uint256 indexed proposalId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "DAO: only admin");
        _;
    }

    /**
     * @param _governanceToken address of token that exposes getPastVotes & getPastTotalSupply
     * @param _votingDelay blocks to wait before voting starts
     * @param _votingPeriod how many blocks voting lasts
     * @param _quorumBps quorum percent in basis points (10000 = 100%)
     */
    constructor(
        IERC20VotesLike _governanceToken,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _quorumBps
    ) {
        require(address(_governanceToken) != address(0), "invalid token");
        require(_quorumBps <= 10000, "quorum > 10000");
        governanceToken = _governanceToken;
        admin = msg.sender;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        quorumBps = _quorumBps;
    }

    /* ===================== Proposal creation ===================== */

    /**
     * @notice Create a governance proposal that (optionally) will execute a single on-chain call if passed.
     * @param title short title for proposal
     * @param description longer description (off-chain storage is recommended)
     * @param target contract address to call on execute (use address(0) and empty calldata for no-op proposals)
     * @param value ETH value (wei) to send with the execution call
     * @param callData calldata for the execution call
     * @return proposalId new proposal id
     */
    function createProposal(
        string calldata title,
        string calldata description,
        address target,
        uint256 value,
        bytes calldata callData
    ) external returns (uint256) {
        uint256 id = ++proposalCount;

        // snapshot block = current block number (we will use it to query getPastVotes)
        uint256 snapshot = block.number;

        // set voting window
        uint256 start = block.number + votingDelay;
        uint256 end = start + votingPeriod;

        proposals[id] = Proposal({
            id: id,
            proposer: msg.sender,
            title: title,
            description: description,
            target: target,
            value: value,
            callData: callData,
            snapshotBlock: snapshot,
            startBlock: start,
            endBlock: end,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            finalized: false,
            canceled: false
        });

        emit ProposalCreated(id, msg.sender, start, end);
        return id;
    }

    /* ===================== Voting ===================== */

    /**
     * @notice Cast a vote on a proposal. Voting power is read from token.getPastVotes(voter, proposal.snapshotBlock).
     * @param proposalId id of the proposal
     * @param support true = for, false = against
     */
    function vote(uint256 proposalId, bool support) external {
        Proposal storage prop = proposals[proposalId];
        require(prop.id != 0, "DAO: proposal not found");
        require(block.number >= prop.startBlock, "DAO: voting not started");
        require(block.number <= prop.endBlock, "DAO: voting ended");
        require(!prop.canceled, "DAO: proposal canceled");

        Receipt storage r = receipts[proposalId][msg.sender];
        require(!r.hasVoted, "DAO: already voted"); // prevent double voting

        // read voting power at the recorded snapshot block
        uint256 voterPower = governanceToken.getPastVotes(msg.sender, prop.snapshotBlock);
        require(voterPower > 0, "DAO: no voting power");

        // record receipt
        r.hasVoted = true;
        r.support = support;
        r.votes = voterPower;

        if (support) {
            prop.forVotes += voterPower;
        } else {
            prop.againstVotes += voterPower;
        }

        emit Voted(proposalId, msg.sender, support, voterPower);
    }

    /* ===================== Finalize & Execution ===================== */

    /**
     * @notice Finalize proposal after voting period ended; compute whether it passed.
     * @dev Anyone can call finalize after voting window ends.
     * @param proposalId id to finalize
     * @return passed whether the proposal passed
     */
    function finalizeProposal(uint256 proposalId) public returns (bool passed) {
        Proposal storage prop = proposals[proposalId];
        require(prop.id != 0, "DAO: not found");
        require(block.number > prop.endBlock, "DAO: voting not ended");
        require(!prop.finalized, "DAO: already finalized");

        prop.finalized = true;

        // compute quorum based on snapshot total supply (at snapshotBlock)
        uint256 totalSupplyAtSnapshot = governanceToken.getPastTotalSupply(prop.snapshotBlock);
        uint256 quorum = (totalSupplyAtSnapshot * quorumBps) / 10000;

        // passing rule: forVotes > againstVotes AND forVotes >= quorum
        if (prop.forVotes > prop.againstVotes && prop.forVotes >= quorum) {
            passed = true;
        } else {
            passed = false;
        }

        emit ProposalFinalized(proposalId, passed);
    }

    /**
     * @notice Execute a passed proposal's call (single target). Can only execute once.
     * @param proposalId id to execute
     */
    function executeProposal(uint256 proposalId) external returns (bool success) {
        Proposal storage prop = proposals[proposalId];
        require(prop.id != 0, "DAO: not found");
        require(prop.finalized, "DAO: not finalized");
        require(!prop.executed, "DAO: already executed");
        require(!prop.canceled, "DAO: canceled");

        // recompute pass condition to be safe (could optionally require finalize called)
        uint256 totalSupplyAtSnapshot = governanceToken.getPastTotalSupply(prop.snapshotBlock);
        uint256 quorum = (totalSupplyAtSnapshot * quorumBps) / 10000;
        require(prop.forVotes > prop.againstVotes && prop.forVotes >= quorum, "DAO: not passed");

        // mark executed before external call (checks-effects-interactions)
        prop.executed = true;

        // if target is zero-address or calldata empty, it's a no-op execution
        if (prop.target == address(0) || prop.callData.length == 0) {
            emit ProposalExecuted(proposalId, msg.sender, true);
            return true;
        }

        // perform low-level call
        (success, ) = prop.target.call{value: prop.value}(prop.callData);
        emit ProposalExecuted(proposalId, msg.sender, success);
        return success;
    }

    /* ===================== Admin / Emergency ===================== */

    /**
     * @notice Cancel a proposal (admin only). Useful to stop malicious proposals pre-execution.
     * @param proposalId id to cancel
     */
    function cancelProposal(uint256 proposalId) external onlyAdmin {
        Proposal storage prop = proposals[proposalId];
        require(prop.id != 0, "DAO: not found");
        require(!prop.canceled, "DAO: already canceled");
        prop.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Update governance parameters (admin only)
     */
    function setVotingDelay(uint256 _votingDelay) external onlyAdmin {
        votingDelay = _votingDelay;
    }

    function setVotingPeriod(uint256 _votingPeriod) external onlyAdmin {
        votingPeriod = _votingPeriod;
    }

    function setQuorumBps(uint256 _quorumBps) external onlyAdmin {
        require(_quorumBps <= 10000, "DAO: invalid quorum");
        quorumBps = _quorumBps;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "DAO: zero admin");
        admin = newAdmin;
    }

    // allow receiving ETH if proposals want to move ETH
    receive() external payable {}
}
