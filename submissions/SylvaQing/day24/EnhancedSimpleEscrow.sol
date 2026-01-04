// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 托管服务: 具有超时、取消和事件的安全托管合约
contract EnhancedSimpleEscrow{
    
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter; //解决争议的受信任第三方

    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }
    EscrowState public state; //托管状态管理
 
    uint256 public amount; //锁定在托管中的 ETH
    uint256 public depositTime; //跟踪买家何时付款
    uint256 public deliveryTimeout; //是卖家交付的窗口期（以秒为单位）

    // 事件：存款、确认、争议（提出/解决）、取消
    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator); //当托管被取消时触发，无论是通过超时还是相互协议
    event DeliveryTimeoutReached(address indexed buyer); //如果买家在交付窗口到期后取消，则触发。

    // 构造函数：卖家、第三方、超时时间
    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
        deliveryTimeout = _deliveryTimeout;
    }
    // 阻止随机 ETH 转账
    receive() external payable {
        revert("Direct payments not allowed");
    }
    
    // 买家将资金发送到托管
    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid");
        require(msg.value > 0, "Amount must be greater than zero");

        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);
    }

    // 买家标记交易完成
    function confirmDelivery() external {
        require(msg.sender == buyer, "Only buyer can confirm");
        require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");

        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    // 买家或卖家标记问题
    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(state == EscrowState.AWAITING_DELIVERY, "Can't dispute now");

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    // 仲裁人决定结果
    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter, "Only arbiter can resolve");
        require(state == EscrowState.DISPUTED, "No dispute to resolve");

        state = EscrowState.COMPLETE;
        if (_releaseToSeller) {
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount); //支付给卖家
        } else {
            payable(buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount); //退款给买家
        }
    }

    // 如果卖家延迟，买家取消
    function cancelAfterTimeout() external {
        require(msg.sender == buyer, "Only buyer can trigger timeout cancellation");
        require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel in current state");
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached"); //超时逻辑

        state = EscrowState.CANCELLED;
        payable(buyer).transfer(address(this).balance); //不是 amount，只是为了额外安全——以防有任何意外进入合约
        emit EscrowCancelled(buyer);
        emit DeliveryTimeoutReached(buyer);
    }

    // 任何一方在完成前取消
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

    // 查看剩余多少时间      
    function getTimeLeft() external view returns (uint256) {
        if (state != EscrowState.AWAITING_DELIVERY) return 0;
        if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        return (depositTime + deliveryTimeout) - block.timestamp;
    }




}