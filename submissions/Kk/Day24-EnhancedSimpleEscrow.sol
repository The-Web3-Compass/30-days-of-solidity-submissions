// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnhancedSimpleEscrow {
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;

    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED } 
    EscrowState public state;

    uint256 public amount;
    uint256 public depositTime;
    uint256 public deliveryTimeout;

    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor (address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
        deliveryTimeout = _deliveryTimeout;
    }

    function deposit() external payable{
        require(msg.value > 0, "Amount must be greater than zero");
        require(msg.sender == buyer, "Only buyer can deposit");
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid");

        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        //emit PaymentDeposited(buyer, amount);
        emit PaymentDeposited(msg.sender, msg.value);
    }

    function confirmDelivery() external{
        require(msg.sender == buyer, "Only buyer can confirm");
        require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");
        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);
        //emit DeliveryConfirmed(buyer, seller, amount);
        emit DeliveryConfirmed(msg.sender, seller, amount);
    }

    receive() external payable {
        revert("Direct payments not allowed");
    }
}
