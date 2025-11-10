// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title SimpleDAO - member-based governance for proposals & voting
/// @notice One member = one vote. Proposals can include multiple calls (targets, values, calldata).
/// @dev Simple, auditable logic intended as a learning scaffold (not a full production timelock/companion token DAO).
contract SimpleDAO {
    /* ========== EVENTS ========== */
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        uint256 startTime,
        uint256 endTime,
        string description
    );
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support);
    event ProposalExecuted(uint256 indexed id);
    event ProposalQueued(uint256 indexed id);

    /* ========== STRUCTS ========== */
    struct Proposal {
        uint256 id;
        address proposer;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string description;
        uint256 startTime; // unix timestamp when voting starts
        uint256 endTime;   // unix timestamp when voting ends
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
    }

    /* ========== STATE ========== */
    mapping(address => bool) public isMember;            // membership mapping
    uint256 public memberCount;                          // total members (voting weight = 1)
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // votes: proposalId => voter => bool (has voted)
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // governance parameters
    uint256 public votingPeriod; // seconds
    uint256 public quorum;       // minimum number of forVotes required for proposal to pass

    address public admin; // admin can add/remove members and change params (simple governance for learning)

    /* ========== MODIFIERS ========== */
    modifier onlyAdmin() {
        require(msg.sender == admin, "SimpleDAO: only admin");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "SimpleDAO: only member");
        _;
    }

    constructor(uint256 _votingPeriodSeconds, uint256 _quorum) {
        require(_votingPeriodSeconds > 0, "voting period > 0");
        votingPeriod = _votingPeriodSeconds;
        quorum = _quorum;
        admin = msg.sender;
    }

    /* ========== ADMIN / MEMBERSHIP ========== */

    /// @notice Add a member (gives them 1 vote). Admin only for this simple example.
    function addMember(address _member) external onlyAdmin {
        require(_member != address(0), "zero address");
        require(!isMember[_member], "already member");
        isMember[_member] = true;
        memberCount += 1;
        emit MemberAdded(_member);
    }

    /// @notice Remove a member. Admin only.
    function removeMember(address _member) external onlyAdmin {
        require(isMember[_member], "not member");
        isMember[_member] = false;
        memberCount -= 1;
        emit MemberRemoved(_member);
    }

    /// @notice Change quorum (admin only)
    function setQuorum(uint256 _quorum) external onlyAdmin {
        quorum = _quorum;
    }

    /// @notice Change voting period
    function setVotingPeriod(uint256 _seconds) external onlyAdmin {
        require(_seconds > 0, "voting period > 0");
        votingPeriod = _seconds;
    }

    /* ========== PROPOSAL CREATION ========== */

    /// @notice Create a proposal that can execute multiple calls once passed
    /// @param targets array of target contract addresses
    /// @param values array of ETH values to send with each call (in wei)
    /// @param calldatas array of calldata bytes for each call
    /// @param description human-readable description
    function propose(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        string calldata description
    ) external onlyMember returns (uint256) {
        require(
            targets.length == values.length && targets.length == calldatas.length,
            "SimpleDAO: proposal param length mismatch"
        );
        require(targets.length > 0, "SimpleDAO: empty proposal");

        uint256 id = ++proposalCount;
        uint256 start = block.timestamp;
        uint256 end = start + votingPeriod;

        proposals[id] = Proposal({
            id: id,
            proposer: msg.sender,
            targets: _copyAddresses(targets),
            values: _copyUint256(values),
            calldatas: _copyBytes(calldatas),
            description: description,
            startTime: start,
            endTime: end,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            canceled: false
        });

        emit ProposalCreated(id, msg.sender, start, end, description);
        return id;
    }

    /* ========== VOTING ========== */

    /// @notice Cast a vote (support = true for, false against)
    function vote(uint256 proposalId, bool support) external onlyMember {
        Proposal storage p = proposals[proposalId];
        require(p.id != 0, "SimpleDAO: proposal not found");
        require(block.timestamp >= p.startTime, "SimpleDAO: voting not started");
        require(block.timestamp <= p.endTime, "SimpleDAO: voting ended");
        require(!hasVoted[proposalId][msg.sender], "SimpleDAO: already voted");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            p.forVotes += 1;
        } else {
            p.againstVotes += 1;
        }
        emit VoteCast(msg.sender, proposalId, support);
    }

    /* ========== VIEW HELPERS ========== */

    function state(uint256 proposalId) public view returns (string memory) {
        Proposal storage p = proposals[proposalId];
        require(p.id != 0, "SimpleDAO: not found");

        if (p.canceled) return "Canceled";
        if (block.timestamp < p.startTime) return "Pending";
        if (block.timestamp <= p.endTime) return "Active";
        if (p.executed) return "Executed";
        if (_passed(p)) return "Succeeded";
        return "Defeated";
    }

    function _passed(Proposal storage p) internal view returns (bool) {
        // A proposal passes if: forVotes > againstVotes AND forVotes >= quorum
        return (p.forVotes > p.againstVotes) && (p.forVotes >= quorum);
    }

    /* ========== EXECUTION ========== */

    /// @notice Execute a passed proposal. Will attempt to perform each call in order.
    function execute(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(p.id != 0, "SimpleDAO: not found");
        require(block.timestamp > p.endTime, "SimpleDAO: voting not ended");
        require(!p.executed, "SimpleDAO: already executed");
        require(!p.canceled, "SimpleDAO: canceled");
        require(_passed(p), "SimpleDAO: proposal not passed");

        p.executed = true;

        // Execute each call. If any call reverts, revert entire execution to keep atomicity.
        for (uint256 i = 0; i < p.targets.length; i++) {
            (bool success, bytes memory returndata) = p.targets[i].call{value: p.values[i]}(p.calldatas[i]);
            require(success, _getRevertMsg(returndata));
        }

        emit ProposalExecuted(proposalId);
    }

    /// @notice Cancel proposal (admin only)
    function cancel(uint256 proposalId) external onlyAdmin {
        Proposal storage p = proposals[proposalId];
        require(p.id != 0, "SimpleDAO: not found");
        require(!p.executed, "SimpleDAO: already executed");
        p.canceled = true;
        emit ProposalQueued(proposalId);
    }

    /* ========== UTIL / FALLBACKS ========== */

    receive() external payable {}
    fallback() external payable {}

    // --- internal helpers to copy calldata arrays into storage-friendly memory arrays ---
    function _copyAddresses(address[] calldata a) internal pure returns (address[] memory b) {
        b = new address[](a.length);
        for (uint256 i = 0; i < a.length; i++) b[i] = a[i];
    }
    function _copyUint256(uint256[] calldata a) internal pure returns (uint256[] memory b) {
        b = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) b[i] = a[i];
    }
    function _copyBytes(bytes[] calldata a) internal pure returns (bytes[] memory b) {
        b = new bytes[](a.length);
        for (uint256 i = 0; i < a.length; i++) b[i] = a[i];
    }

    // decode revert reason if present (copied minimal helper)
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68) return "SimpleDAO: call reverted";
        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
}
