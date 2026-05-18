// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title  SimpleMultiSig — Misty Treasury 🔐
/// @author rainwaters11 — Day 24: Multi-Signature Treasury Wallet
/// @notice An M-of-N multi-signature wallet. N owners hold keys; M must
///         confirm before any transaction can execute.
///
/// @dev    THE "2-OF-3 SWEET SPOT" EXPLAINED
///         ┌───────────────────────────────────────────────────────────────┐
///         │  2-of-2 → Maximum security. BUT: one lost key = funds locked  │
///         │           forever. Too brittle for production.                │
///         │                                                               │
///         │  2-of-3 → Industry standard (Gnosis Safe, Coinbase Vault).   │
///         │           You + Vanessa + backup key.                         │
///         │           Lose your phone? You + Vanessa sign with backup.    │
///         │           Backup compromised? You + Vanessa block attacker.   │
///         └───────────────────────────────────────────────────────────────┘
///
///         THE WORKFLOW (3-step lifecycle of every transaction)
///         ┌───────────────────────────────────────────────────────────────┐
///         │  1. submitTransaction  → any owner proposes a TX              │
///         │  2. confirmTransaction → each owner adds their signature      │
///         │  3. executeTransaction → any owner triggers execution once    │
///         │                          confirmationCount >= required         │
///         └───────────────────────────────────────────────────────────────┘
///
///         MAPPING-OF-MAPPINGS (the key data structure)
///         isConfirmed[txId][ownerAddress] = true/false
///         This lets us answer "has this specific owner confirmed this
///         specific TX?" in O(1) with zero looping — gas-efficient and
///         secure.  Each owner can only confirm once per TX.
///
///         SAFETY: Checks-Effects-Interactions pattern throughout.
///         The ETH transfer in executeTransaction is the LAST operation
///         after all state (executed flag) is updated. This prevents
///         reentrancy without needing an external guard.
///
///         USE CASES IN MISTYCOIN-CORE
///         • Treasury: 2-of-3 with you, Vanessa, and a cold backup key.
///         • Protocol upgrades: require 3-of-5 from core team.
///         • Emergency shutdown: 4-of-5 to prevent unilateral action.
contract SimpleMultiSig {

    // ─── Structs ──────────────────────────────────────────────────────────────

    /// @notice Represents a proposed transaction waiting for confirmations.
    struct Transaction {
        address to;             // destination address
        uint256 value;          // ETH to send (in wei)
        bytes   data;           // call data (for contract interactions)
        bool    executed;       // has this TX been sent?
        uint256 confirmations;  // how many owners have confirmed so far
    }

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice All owners of this multi-sig wallet.
    address[] public owners;

    /// @notice Number of confirmations required to execute a transaction.
    uint256 public requiredConfirmations;

    /// @dev Quick O(1) membership check — avoids looping through `owners`.
    mapping(address => bool) public isOwner;

    /// @dev THE MAPPING-OF-MAPPINGS:
    ///      isConfirmed[txId][ownerAddress] = true if that owner confirmed.
    ///      Tracks each owner's vote on each TX independently.
    ///      Prevents double-voting without any loop or enumeration.
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    /// @notice All proposed transactions, indexed by their txId.
    Transaction[] public transactions;

    // ─── Events ───────────────────────────────────────────────────────────────

    event TransactionSubmitted(
        uint256 indexed txId,
        address indexed submitter,
        address indexed to,
        uint256 value,
        bytes   data
    );
    event TransactionConfirmed(uint256 indexed txId, address indexed owner);
    event ConfirmationRevoked(uint256 indexed txId, address indexed owner);
    event TransactionExecuted(uint256 indexed txId, address indexed executor);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error NotOwner();
    error InvalidOwnerAddress();       // zero address in owner list
    error DuplicateOwner();            // same address appears twice
    error InvalidRequirement();        // required == 0 or > owners.length
    error TxDoesNotExist();
    error TxAlreadyExecuted();
    error AlreadyConfirmed();          // owner already voted on this TX
    error NotConfirmed();              // owner hasn't confirmed — can't revoke
    error InsufficientConfirmations(); // not enough votes to execute
    error ExecutionFailed();           // low-level call returned false

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint256 txId) {
        if (txId >= transactions.length) revert TxDoesNotExist();
        _;
    }

    modifier notExecuted(uint256 txId) {
        if (transactions[txId].executed) revert TxAlreadyExecuted();
        _;
    }

    modifier notConfirmed(uint256 txId) {
        if (isConfirmed[txId][msg.sender]) revert AlreadyConfirmed();
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @notice Deploy the multi-sig with an initial owner set and threshold.
    ///
    /// @dev    VALIDATION RULES
    ///         • No zero addresses in the owner list.
    ///         • No duplicate addresses.
    ///         • requiredConfirmations must be ≥ 1 and ≤ owners.length.
    ///
    ///         EXAMPLE DEPLOYMENTS
    ///         • 2-of-2: owners=[you, Vanessa], required=2
    ///         • 2-of-3: owners=[you, Vanessa, backup], required=2 ← recommended
    ///         • 3-of-5: owners=[5 team members],       required=3
    ///
    /// @param _owners                 Array of owner addresses.
    /// @param _requiredConfirmations  Minimum confirmations to execute a TX.
    constructor(address[] memory _owners, uint256 _requiredConfirmations) {
        if (_owners.length == 0) revert InvalidRequirement();
        if (
            _requiredConfirmations == 0 ||
            _requiredConfirmations > _owners.length
        ) revert InvalidRequirement();

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0))  revert InvalidOwnerAddress();
            if (isOwner[owner])       revert DuplicateOwner();

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredConfirmations = _requiredConfirmations;
    }

    // ─── Core: Submit ─────────────────────────────────────────────────────────

    /// @notice Propose a new transaction. Any owner can do this.
    ///
    /// @dev    The TX starts with 0 confirmations and is NOT auto-confirmed
    ///         by the submitter — they must call confirmTransaction() too.
    ///         This is intentional: separating proposal from approval is a
    ///         security best practice (prevents social-engineering shortcuts).
    ///
    /// @param to     Destination address (EOA or contract).
    /// @param value  ETH to send, in wei. Can be 0 for pure data calls.
    /// @param data   ABI-encoded call data. Use "" for plain ETH transfers.
    /// @return txId  Index of the new transaction in the transactions array.
    function submitTransaction(
        address to,
        uint256 value,
        bytes calldata data
    )
        external
        onlyOwner
        returns (uint256 txId)
    {
        txId = transactions.length;

        transactions.push(Transaction({
            to:            to,
            value:         value,
            data:          data,
            executed:      false,
            confirmations: 0
        }));

        emit TransactionSubmitted(txId, msg.sender, to, value, data);
    }

    // ─── Core: Confirm ────────────────────────────────────────────────────────

    /// @notice Add your confirmation (vote) to a pending transaction.
    ///
    /// @dev    MAPPING-OF-MAPPINGS in action:
    ///         isConfirmed[txId][msg.sender] = true
    ///         This is O(1) — no array scanning, no gas spike as owner count grows.
    ///
    ///         After this call, transactions[txId].confirmations is incremented.
    ///         Once it hits requiredConfirmations, the TX becomes executable.
    ///
    /// @param txId  Index of the transaction to confirm.
    function confirmTransaction(uint256 txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
        notConfirmed(txId)
    {
        // EFFECTS — update state first (C-E-I)
        isConfirmed[txId][msg.sender] = true;
        transactions[txId].confirmations += 1;

        emit TransactionConfirmed(txId, msg.sender);
    }

    // ─── Core: Revoke ─────────────────────────────────────────────────────────

    /// @notice Change your mind — revoke a previously given confirmation.
    ///         Useful if you spot an error in the TX details before execution.
    ///
    /// @param txId  Index of the transaction to un-confirm.
    function revokeConfirmation(uint256 txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
    {
        if (!isConfirmed[txId][msg.sender]) revert NotConfirmed();

        // EFFECTS
        isConfirmed[txId][msg.sender] = false;
        transactions[txId].confirmations -= 1;

        emit ConfirmationRevoked(txId, msg.sender);
    }

    // ─── Core: Execute ────────────────────────────────────────────────────────

    /// @notice Execute a transaction once it has enough confirmations.
    ///
    /// @dev    SAFETY CHECK (the requirement of Day 24):
    ///         The gate is:
    ///           transactions[txId].confirmations >= requiredConfirmations
    ///         If this is false → InsufficientConfirmations() is reverted.
    ///         No amount of social pressure or manual override can bypass this —
    ///         it is enforced at the EVM level.
    ///
    ///         CHECKS-EFFECTS-INTERACTIONS:
    ///         1. CHECK  — confirmations >= required, not already executed.
    ///         2. EFFECT — mark executed = true BEFORE the external call.
    ///         3. INTERACT — low-level `.call` sends ETH + data.
    ///
    ///         Marking executed BEFORE the call prevents a reentrancy attacker
    ///         from calling executeTransaction again inside the recipient's
    ///         fallback function (the TX would be marked executed → revert).
    ///
    /// @param txId  Index of the transaction to execute.
    function executeTransaction(uint256 txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
    {
        Transaction storage txn = transactions[txId];

        // ── SAFETY CHECK ──────────────────────────────────────────────────────
        // This is the M-of-N gate. ONLY executable when confirmations >= required.
        if (txn.confirmations < requiredConfirmations)
            revert InsufficientConfirmations();

        // ── EFFECTS (before external call — C-E-I) ────────────────────────────
        txn.executed = true;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        if (!success) revert ExecutionFailed();

        emit TransactionExecuted(txId, msg.sender);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Returns the full owner list.
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /// @notice Returns the number of transactions ever submitted.
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    /// @notice Returns all details of a specific transaction.
    function getTransaction(uint256 txId)
        external
        view
        txExists(txId)
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool    executed,
            uint256 confirmations
        )
    {
        Transaction storage txn = transactions[txId];
        return (txn.to, txn.value, txn.data, txn.executed, txn.confirmations);
    }

    /// @notice Returns whether a specific owner has confirmed a specific TX.
    ///
    /// @dev    Direct O(1) read from the mapping-of-mappings.
    ///         isConfirmed[txId][owner] — the core data structure of a multi-sig.
    function hasConfirmed(uint256 txId, address owner)
        external
        view
        returns (bool)
    {
        return isConfirmed[txId][owner];
    }

    /// @notice Returns how many confirmations a TX still needs before execution.
    function confirmationsNeeded(uint256 txId)
        external
        view
        txExists(txId)
        returns (uint256)
    {
        uint256 current = transactions[txId].confirmations;
        if (current >= requiredConfirmations) return 0;
        return requiredConfirmations - current;
    }

    // ─── Receive ETH ──────────────────────────────────────────────────────────

    /// @dev Accept plain ETH deposits so the wallet can hold a treasury balance.
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /// @dev Catch calls with non-empty data that match no function selector.
    fallback() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}
