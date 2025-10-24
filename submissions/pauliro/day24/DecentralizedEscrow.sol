 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EnhancedSimpleEscrow {
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }

    address public immutable arbiter;
    address public immutable seller;
    address public immutable buyer;
    

    uint256 public amount;
    EscrowState public state;
    uint256 public deliveryTimeout; // seconds after deposit
    uint256 public depositTime;

    
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");
        buyer = msg.sender;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
        seller = _seller;
        deliveryTimeout = _deliveryTimeout;
    }

    receive() external payable {
        revert("Direct payments are not allowed");
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only the buyer can deposit");
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid");
        require(msg.value > 0, "Amount must be greater than zero");
        amount = msg.value;
        depositTime = block.timestamp;
        state = EscrowState.AWAITING_DELIVERY;
        emit PaymentDeposited(buyer, amount);
    }

    function confirmDelivery() external {
        require(msg.sender == buyer, "Only the buyer can confirm");
        require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");
        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(state == EscrowState.AWAITING_DELIVERY, "Can't dispute now");

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter, "Only the arbiter can resolve");
        require(state == EscrowState.DISPUTED, "No dispute to be resolved");
        state = EscrowState.COMPLETE;
        if (_releaseToSeller) {
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        } else {
            payable(buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount);
        }
    }

    function cancelAfterTimeout() external {
        require(msg.sender == buyer, "Only buyer can trigger timeout cancellation");
        require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel in current state");
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");
        payable(buyer).transfer(address(this).balance);
        state = EscrowState.CANCELLED;    
        emit EscrowCancelled(buyer);
        emit DeliveryTimeoutReached(buyer);
    }

    function getTimeLeft() external view returns (uint256) {
        if (state != EscrowState.AWAITING_DELIVERY) return 0;
        if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        return (depositTime + deliveryTimeout) - block.timestamp;
    }

    function cancelMutual() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(
            state == EscrowState.AWAITING_DELIVERY || state == EscrowState.AWAITING_PAYMENT,
            "Cannot cancel now"
        );
        EscrowState previousState = state;
        state = EscrowState.CANCELLED;
        if (previousState == EscrowState.AWAITING_DELIVERY) {
            payable(buyer).transfer(address(this).balance);
        }
        emit EscrowCancelled(msg.sender);
    }

    
}

