// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract simpleEscrow {
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;

    enum EscrowState{AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTE, CANCELLED}

    EscrowState public state;

    uint public amount;
    uint public depositTime;
    uint public deliveryTimeout;

    event PaymentDeposited(address indexed buyer, uint indexed amount);
    event DeliveryConfirmed(address indexed buyer,address seller, uint indexed amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter,address recipient, uint indexed amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(address _seller, address _arbiter, uint _deliveryTimeout){
        require(_deliveryTimeout > 0, "delivery timeout must be greater than 0");

        buyer = msg.sender;
        arbiter = _arbiter;
        seller = _seller;
        state = EscrowState.AWAITING_PAYMENT;
        deliveryTimeout = _deliveryTimeout;
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid");
        require(msg.value > 0, "Amount must be greater than zero");

        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;

        emit PaymentDeposited(msg.sender, msg.value);
    }

    function confirmDelivery() external {
        require(state == EscrowState.AWAITING_DELIVERY, "Already paid");
        require(msg.sender == buyer, "only buyer can confirm");

        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);

        emit DeliveryConfirmed(msg.sender, seller, amount);
    }

    function raiseDispute() external {
        require(state == EscrowState.AWAITING_DELIVERY, "cant dispute now");
        require(msg.sender == buyer || msg.sender == seller, "not authorized");

        state = EscrowState.DISPUTE;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool _releaseToSeller) external payable {
        require(state == EscrowState.AWAITING_DELIVERY, "cant dispute now");
        require(msg.sender == buyer || msg.sender == seller, "not authorized");

        state = EscrowState.COMPLETE;
        if(!_releaseToSeller){
            payable(buyer).transfer(amount);
            emit DisputeResolved(buyer, seller, amount);
        }else{
            payable(seller).transfer(amount);
            emit DisputeResolved(buyer, seller, amount);
        }
    }

    function cancelAfterTimeout() external {
        require(state == EscrowState.AWAITING_DELIVERY, "cant dispute now");
        require(msg.sender == buyer, "only buyer can trigger cancellation");
        require(block.timestamp > deliveryTimeout, "timeout not reached");

        state = EscrowState.CANCELLED;
        payable(buyer).transfer(amount);
        emit EscrowCancelled(msg.sender);
        emit DeliveryTimeoutReached(msg.sender);

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

    function getTimeLeft() external view returns (uint256) {
        if (state != EscrowState.AWAITING_DELIVERY) return 0;
        if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        return (depositTime + deliveryTimeout) - block.timestamp;
    }
}