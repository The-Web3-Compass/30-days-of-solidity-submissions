//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralisedEscrow {
    enum EscrowState {AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETED, DISPUTED, CANCELLED}

    address public immutable buyer; // immutable表示固定的，不能更改的变量
    address public immutable seller;
    address public immutable arbiter;

    EscrowState public state;
    uint256 public amount;
    uint256 public depositTime;
    uint256 public deliveryTimeout; // in seconds 等待买家发货及物流的时间期限

    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address indexed recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        deliveryTimeout = _deliveryTimeout;
        state = EscrowState.AWAITING_PAYMENT;
    }

    receive() external payable {
        revert("Direct payment not allowed"); // 禁止直接发送ETF到合约
    }

    function depositPayment() external payable {
        require(msg.value > 0, "Deposit amount shoule be greater than 0");
        require(msg.sender == buyer, "Only buyer can perform this action");
        require(state == EscrowState.AWAITING_PAYMENT, "Already deposite payment");

        state = EscrowState.AWAITING_DELIVERY;
        amount = msg.value;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);
    }

    function confirmDelivery() external {
        require(msg.sender == buyer, "Only buyer can perform this action");
        require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");

        state = EscrowState.COMPLETED;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can perform this action");
        require(state == EscrowState.AWAITING_DELIVERY, "Only in delivery state can raise dispute");

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool releaseToSeller) external {
        require(msg.sender == arbiter, "Only arbiter can perform this action");
        require(state == EscrowState.DISPUTED, "Not in dispute state");

        state = EscrowState.COMPLETED;
        if (releaseToSeller) {
            payable (seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        } else {
            payable (buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount);
        }
    }

    function cancelAfterTimeout() external {
        require(msg.sender == buyer, "Only buyer can perform this action");
        require(state == EscrowState.AWAITING_DELIVERY, "Only in delivery state can cancel escrow after timeout");
        require(block.timestamp >= depositTime + deliveryTimeout, "Delivery timeout not reached");

        state = EscrowState.CANCELLED;
        payable(buyer).transfer(amount);
        emit DeliveryTimeoutReached(buyer);
        emit EscrowCancelled(buyer);
    }

    function cancelEscrow() external {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can perform this action");
        require(state == EscrowState.AWAITING_PAYMENT || 
                state == EscrowState.AWAITING_DELIVERY, "Only in awaiting payment or delivery state can cancel escrow");
        
        EscrowState previousState = state;
        state = EscrowState.CANCELLED;
        if (previousState == EscrowState.AWAITING_DELIVERY) {
            payable(buyer).transfer(amount);
            //payable(buyer).transfer(address(this).balance);
        }
        emit EscrowCancelled(msg.sender);
    }

    function getDeliveryTimeLeft() external view returns(uint256) {
        if (state != EscrowState.AWAITING_DELIVERY) return 0;
        else if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        else return (depositTime + deliveryTimeout - block.timestamp);
    }
}