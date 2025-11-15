// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title EnhancedSimpleEscrow - 具有超时、取消和事件的安全托管合约
contract EnhancedSimpleEscrow {
    // 枚举，使用enum跟踪交易阶段
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter; // 仲裁人是解决争议的受信任第三方

    uint256 public amount; // 锁定在托管中的ETH
    EscrowState public state;
    uint256 public depositTime;
    uint256 public deliveryTimeout; // 存款后的持续时间（以秒为单位）

    event PaymentDeposited(address indexed buyer, uint256 amount); // 买家成功将ETH存入托管时触发
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount); // 买家确认他们已收到产品或服务时触发
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer); // 买家在交付窗口到期后取消

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        // 设置超时
        require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");
        buyer = msg.sender; // 设置买家
        seller = _seller; 
        arbiter = _arbiter; // 仲裁人，只在出现问题时出现
        state = EscrowState.AWAITING_PAYMENT; // 将合约设置为等待状态————资金尚未存入
        deliveryTimeout = _deliveryTimeout; // 卖家必须交付的时间窗口
    }

    //阻止随机ETH转账

    receive() external payable {
        revert("Direct payments not allowed");
    }

    //买家将资金发送到托管

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid"); //尚未付款时
        require(msg.value > 0, "Amount must be greater than zero");

        amount = msg.value; // 锁定资金，将发送到合约的ETH存储在名为amount的状态变量中
        state = EscrowState.AWAITING_DELIVERY; // 修改状态，等待卖家交付
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

    // 标记问题

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(state == EscrowState.AWAITING_DELIVERY, "Can't dispute now"); // 争议只在交付或者等待时提出

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    // 仲裁人决定结果

    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter, "Only arbiter can resolve");
        require(state == EscrowState.DISPUTED, "No dispute to resolve");

        state = EscrowState.COMPLETE; // 托管现在是关闭的
        // 根据决定释放资金
        if (_releaseToSeller) {
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        } else {
            payable(buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount);
        }
    }

    // 如果卖家延迟，买家取消

    function cancelAfterTimeout() external {
        require(msg.sender == buyer, "Only buyer can trigger timeout cancellation");
        require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel in current state");
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");

        state = EscrowState.CANCELLED; // 将交易标记为已取消，不能触发任何其他操作
        payable(buyer).transfer(address(this).balance);
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

    // 查看在等待交付时剩余多少时间

    function getTimeLeft() external view returns (uint256) {
        if (state != EscrowState.AWAITING_DELIVERY) return 0;
        if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        return (depositTime + deliveryTimeout) - block.timestamp;
    }
}

