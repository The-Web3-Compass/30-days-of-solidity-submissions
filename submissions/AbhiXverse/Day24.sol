// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EnhancedSimpleEscrow {
    enum EscrowState {AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELED}

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;

    uint256 public amount;
    EscrowState public state;
    uint256 public depositTime;
    uint256 public deliveryTimeout;

    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCanceled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        deliveryTimeout = _deliveryTimeout;
        state = EscrowState.AWAITING_PAYMENT;
    }

    receive() external payable {
        revert("Direct payments not allowed");
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(state == EscrowState.AWAITING_PAYMENT, "Payment already made");
        require(msg.value > 0, "Amount must be greater than zero");

        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);
    }

    function confirmDelivery() external {
        require(msg.sender == buyer, "Only seller can confirm delivery");
        require(state == EscrowState.AWAITING_DELIVERY, "Delivery already confirmed");

        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can raise dispute.");
        require(state == EscrowState.AWAITING_DELIVERY, "Dispute can only be raised during delivery period.");
        
        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter, "Only arbiter can resolve dispute.");
        require(state == EscrowState.DISPUTED, "No dispute raised.");
        require(address(this).balance >= amount, "Insufficient balance.");

        if (_releaseToSeller) {
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        } else {
            payable(buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount);
        }
        
        state = EscrowState.COMPLETE;

        emit DisputeResolved(arbiter, seller, amount);
    }

    function cancelAfterTimeout() external {
        require(msg.sender == buyer, "Only buyer can cancel after timeout.");
        require(state == EscrowState.AWAITING_DELIVERY, "Timeout can only be called during delivery period.");
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout period not yet reached.");
        
        payable(buyer).transfer(amount);
        
        state = EscrowState.CANCELED;    
        emit EscrowCanceled(buyer);
        emit DeliveryTimeoutReached(buyer);
    }

    function cancelMutual() external {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can cancel this.");
        require(state == EscrowState.AWAITING_DELIVERY || state == EscrowState.AWAITING_PAYMENT, 

                    "Cannot be canceled at this time.");
        if(state == EscrowState.AWAITING_DELIVERY) 
            payable(buyer).transfer(amount);
        state = EscrowState.CANCELED;
        emit EscrowCanceled(msg.sender);
    }

    function getTimeLeft() external view returns (uint256) {
        require(state == EscrowState.AWAITING_DELIVERY, "Escrow is not in delivery state.");
        if (depositTime + deliveryTimeout - block.timestamp < 0) return 0;
        return depositTime + deliveryTimeout - block.timestamp;
    }
}

