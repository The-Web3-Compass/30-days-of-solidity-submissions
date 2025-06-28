// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Secure Escrow System
 * @notice Holds funds securely until conditions are met or disputes are resolved
 * @dev Implements state machine, reentrancy protection, and role-based access control
 */
contract Escrow {
    // State machine
    enum EscrowState { AWAITING_PAYMENT, FUNDS_DEPOSITED, COMPLETED, DISPUTED, REFUNDED }
    EscrowState public currentState;

    // Contract parties
    address payable public immutable buyer;
    address payable public immutable seller;
    address public immutable arbiter;
    
    // Security & timelocks
    uint256 public immutable disputeDeadline;
    uint256 public constant DISPUTE_PERIOD = 7 days;
    bool private reentrancyLock = false;

    // Events for state transitions
    event FundsDeposited(uint256 amount, address indexed buyer);
    event PaymentReleased(uint256 amount, address indexed seller);
    event RefundIssued(uint256 amount, address indexed buyer);
    event DisputeRaised(address indexed initiator, string reason);
    event DisputeResolved(bool sellerAwarded, string resolution);
    event StateChanged(EscrowState newState);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Unauthorized: Buyer only");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Unauthorized: Arbiter only");
        _;
    }

    modifier stateCheck(EscrowState expectedState) {
        require(currentState == expectedState, "Invalid state transition");
        _;
    }

    modifier nonReentrant() {
        require(!reentrancyLock, "Reentrancy detected");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(address payable _seller, address _arbiter) payable {
        require(_seller != address(0), "Invalid seller address");
        require(_arbiter != address(0), "Invalid arbiter address");
        require(msg.value > 0, "Initial deposit required");
        
        buyer = payable(msg.sender);
        seller = _seller;
        arbiter = _arbiter;
        disputeDeadline = block.timestamp + DISPUTE_PERIOD;
        currentState = EscrowState.FUNDS_DEPOSITED;
        
        emit FundsDeposited(msg.value, msg.sender);
        emit StateChanged(EscrowState.FUNDS_DEPOSITED);
    }

    /// @notice Buyer confirms delivery and releases funds to seller
    function releasePayment() 
        external 
        onlyBuyer 
        stateCheck(EscrowState.FUNDS_DEPOSITED)
        nonReentrant
    {
        currentState = EscrowState.COMPLETED;
        uint256 amount = address(this).balance;
        
        (bool success, ) = seller.call{value: amount}("");
        require(success, "Payment transfer failed");
        
        emit PaymentReleased(amount, seller);
        emit StateChanged(EscrowState.COMPLETED);
    }

    /// @notice Raise a dispute (available to both parties)
    function raiseDispute(string calldata reason) 
        external 
        stateCheck(EscrowState.FUNDS_DEPOSITED)
    {
        require(msg.sender == buyer || msg.sender == seller, "Unauthorized party");
        currentState = EscrowState.DISPUTED;
        
        emit DisputeRaised(msg.sender, reason);
        emit StateChanged(EscrowState.DISPUTED);
    }

    /// @notice Arbiter resolves dispute
    function resolveDispute(bool awardSeller, string calldata resolution) 
        external 
        onlyArbiter 
        stateCheck(EscrowState.DISPUTED)
        nonReentrant
    {
        uint256 amount = address(this).balance;
        currentState = awardSeller ? EscrowState.COMPLETED : EscrowState.REFUNDED;
        
        if (awardSeller) {
            (bool success, ) = seller.call{value: amount}("");
            require(success, "Payment transfer failed");
            emit PaymentReleased(amount, seller);
        } else {
            (bool success, ) = buyer.call{value: amount}("");
            require(success, "Refund transfer failed");
            emit RefundIssued(amount, buyer);
        }
        
        emit DisputeResolved(awardSeller, resolution);
        emit StateChanged(currentState);
    }

    /// @notice Automatic refund if no action before deadline
    function deadlineRefund() 
        external 
        stateCheck(EscrowState.FUNDS_DEPOSITED)
        nonReentrant
    {
        require(block.timestamp > disputeDeadline, "Deadline not passed");
        currentState = EscrowState.REFUNDED;
        uint256 amount = address(this).balance;
        
        (bool success, ) = buyer.call{value: amount}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(amount, buyer);
        emit StateChanged(EscrowState.REFUNDED);
    }

    // Prevent accidental ETH transfers
    receive() external payable {
        revert("Direct payments not allowed");
    }
}