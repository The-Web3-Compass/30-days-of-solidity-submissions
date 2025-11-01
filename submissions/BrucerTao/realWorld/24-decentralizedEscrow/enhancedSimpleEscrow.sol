// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EnhancedSimpleEscrow {
    enum EscrowState { AWATING_PAYMENT, AWATING_DELIVER, COMPLETE, DISPUTED, CANCELLED }

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;  //第三方仲裁

    uint256 public amount;
    EscrowState public state;
    uint256 public depositTime;   //买家付款时间
    uint256 public deliveryTimeout;  //卖家必须交付时间

    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "delivery timeout must be greater than zero");
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWATING_PAYMENT;
        deliveryTimeout = _deliveryTimeout;

    }

    receive() external payable {
        revert("Direct payments not allowed");
    }

    //买家汇款到第三方托管账户
    function deposit() external payable {
        require(msg.sender == buyer, "only buyer can deposit");
        require(state == EscrowState.AWATING_PAYMENT, "already paid");
        require(msg.value > 0, "amount must be greater than zero");

        amount = msg.value;
        state = EscrowState.AWATING_DELIVER;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);

    }

    //买家确认交易完成
    function confirmDelivery() external {
        require(msg.sender == buyer, "only buyer can confirm");
        require(state == EscrowState.AWATING_DELIVER, "not in delivery state");

        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer, seller, amount);

    }

    //买家或者卖家提出问题
    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "not authorized");
        require(state == EscrowState.AWATING_DELIVER, "cannot dispute now");

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);

    }

    //仲裁处理结果
    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter, "only arbiter can resolve");
        require(state == EscrowState.DISPUTED, "no dispute to resolve");

        state = EscrowState.COMPLETE;
        if(_releaseToSeller){
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        }else {
            payable(buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount);
        }

    }

    //若卖家延迟发货，买家取消订单
    function cancelAfterTimeout() external {
        require(msg.sender == buyer, "only buyer can trigger timeout cancellation");
        require(state == EscrowState.AWATING_DELIVER, "cannot cancel in current state");
        require(block.timestamp >= depositTime + deliveryTimeout, "timeout not reached");

        state = EscrowState.CANCELLED;
        payable(buyer).transfer(address(this).balance);
        emit EscrowCancelled(buyer);
        emit DeliveryTimeoutReached(buyer);

    }

    //任何一方在交易完成前取消交易
    function cancelMutual() external {
        require(msg.sender == buyer || msg.sender == seller, "not authorized");
        require(
            state == EscrowState.AWATING_DELIVER || state == EscrowState.AWATING_PAYMENT,
            "cannot cancel now"
        );

        EscrowState previousState = state;
        state = EscrowState.CANCELLED;
        if(previousState == EscrowState.AWATING_DELIVER){
            payable(buyer).transfer(address(this).balance);
        }
        emit EscrowCancelled(msg.sender);

    }

    function getTimeLeft() external view returns (uint256) {
        if(state != EscrowState.AWATING_DELIVER) return 0;
        if(block.timestamp >= depositTime + deliveryTimeout) return 0;
        return (depositTime + deliveryTimeout) - block.timestamp;
    }

}