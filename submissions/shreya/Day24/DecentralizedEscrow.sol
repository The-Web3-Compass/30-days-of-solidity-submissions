// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleEscrow {
    // Enum to represent the different states of the escrow agreement.
    enum State {
        AWAITING_PAYMENT, // The contract is waiting for the buyer to deposit funds.
        AWAITING_DELIVERY, // The buyer has deposited funds, and is waiting for the seller to deliver.
        COMPLETE, // The transaction is complete, and the funds have been released.
        DISPUTED, // A dispute has been raised and is awaiting the arbiter's resolution.
        CANCELLED // The agreement has been cancelled.
    }

    // State variables to store the addresses of the parties involved.
    address public immutable buyer;
    address payable public immutable seller;
    address public immutable arbiter;

    // The amount of the transaction.
    uint256 public amount;

    // The current state of the escrow agreement.
    State public currentState;

    // Modifiers to restrict function access to specific roles.
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can call this function.");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can call this function.");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only the arbiter can call this function.");
        _;
    }

    // Events to log significant actions within the contract.
    event FundsDeposited(address indexed depositor, uint256 amount);
    event DeliveryConfirmed(address indexed confirmer);
    event DisputeRaised(address indexed disputer);
    event DisputeResolved(address indexed resolver, address indexed recipient, uint256 amount);
    event EscrowCancelled(address indexed canceller);

    constructor(address payable _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        currentState = State.AWAITING_PAYMENT;
    }

    function deposit() external payable onlyBuyer {
        require(currentState == State.AWAITING_PAYMENT, "Funds have already been deposited.");
        amount = msg.value;
        currentState = State.AWAITING_DELIVERY;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function confirmDelivery() external onlyBuyer {
        require(currentState == State.AWAITING_DELIVERY, "Cannot confirm delivery in the current state.");
        currentState = State.COMPLETE;
        seller.transfer(address(this).balance);
        emit DeliveryConfirmed(msg.sender);
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Only the buyer or seller can raise a dispute.");
        require(currentState == State.AWAITING_DELIVERY, "A dispute can only be raised while awaiting delivery.");
        currentState = State.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool releaseToSeller) external onlyArbiter {
        require(currentState == State.DISPUTED, "There is no active dispute to resolve.");
        currentState = State.COMPLETE;
        if (releaseToSeller) {
            seller.transfer(address(this).balance);
            emit DisputeResolved(msg.sender, seller, amount);
        } else {
            payable(buyer).transfer(address(this).balance);
            emit DisputeResolved(msg.sender, buyer, amount);
        }
    }

    /** Allows the buyer to cancel the escrow and retrieve their funds if the seller agrees.
     * This is a simple cancellation mechanism and can be expanded for more complex scenarios */
    function cancel() external onlyBuyer {
        require(currentState == State.AWAITING_DELIVERY, "Cannot cancel in the current state.");
        // In a real-world scenario, you might want a more robust cancellation mechanism,
        // such as requiring mutual consent from the seller.
        currentState = State.CANCELLED;
        payable(buyer).transfer(address(this).balance);
        emit EscrowCancelled(msg.sender);
    }
}