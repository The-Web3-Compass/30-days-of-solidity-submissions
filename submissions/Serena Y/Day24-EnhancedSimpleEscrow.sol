
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title EnhancedSimpleEscrow - 具有超时、取消和事件的安全托管合约
contract EnhancedSimpleEscrow {
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;

    uint256 public amount;//锁定在托管中的eth
    EscrowState public state;//托管状态
    uint256 public depositTime;//跟踪买家何时付款
    uint256 public deliveryTimeout; // 存款后的持续时间（以秒为单位）

    event PaymentDeposited(address indexed buyer, uint256 amount);
    //当买家成功将eth存入托管时触发，确认托管已经开始 显示锁定金额
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    //当买家确认他们已收到产品或服务时触发，确认交易完成，表明卖家已收到付款
    event DisputeRaised(address indexed initiator);
    //当买家或卖家提出争议时触发，通知前端并可能触发UI更改（“争议进行中”） 让冲裁人知道需要他们的工作
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    //当仲裁人解决争议并转移资金时触发 用于争议最终状态 显示谁获得了资金以及金额
    event EscrowCancelled(address indexed initiator);
    //当托管被取消时触发，无论是通过超时还是相互协议 用于托管已取消状态更新ui 表明已发出退款
    event DeliveryTimeoutReached(address indexed buyer);
    //交付窗口到期后取消 显示超时原因 资金退还

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");
        //确保交易超时是一个正数
        buyer = msg.sender;
        //买家时部署合约的人
        seller = _seller;
        //卖家地址在部署期间作为参数传入
        arbiter = _arbiter;
        //设置仲裁人
        state = EscrowState.AWAITING_PAYMENT;
        //将合约设置为等待状态
        deliveryTimeout = _deliveryTimeout;
        //设置超时窗口
    }

    receive() external payable {
        revert("Direct payments not allowed");//在 Solidity 中，当合约接收 ETH 而没有任何数据时，会自动调用这个特殊函数。
    }

    function deposit() external payable {//买家将资金发送到托管
        require(msg.sender == buyer, "Only buyer can deposit");
        //只有买家可以存款
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid");
        //只有在尚未付款时
        require(msg.value > 0, "Amount must be greater than zero");
        //ETH 必须大于零

        amount = msg.value;
        //发送到合约的 ETH 存储在名为 amount 的状态变量中
        state = EscrowState.AWAITING_DELIVERY;
        //更改合约状态 我们现在正在等待卖家交付物品或服务
        depositTime = block.timestamp;
        //记录时间戳
        emit PaymentDeposited(buyer, amount);
        //"买家刚刚将 X ETH 存入托管。"
    }

    function confirmDelivery() external {//买家标记交易完成
        require(msg.sender == buyer, "Only buyer can confirm");
        //只有买家可以确认
        require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");
        //只允许在交付窗口期间

        state = EscrowState.COMPLETE;
        //将状态更改为完成
        payable(seller).transfer(amount);
        //将资金释放给卖家
        emit DeliveryConfirmed(buyer, seller, amount);
        //发出交付确认事件
    }

    function raiseDispute() external {//买家或卖家标记争议
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        //只有买家或卖家可以调用此函数
        require(state == EscrowState.AWAITING_DELIVERY, "Can't dispute now");
        //只在交付阶段
    

        state = EscrowState.DISPUTED;//进入争议状态
        emit DisputeRaised(msg.sender);//发出争议事件
    }

    function resolveDispute(bool _releaseToSeller) external {
        //仲裁人决定结果
        require(msg.sender == arbiter, "Only arbiter can resolve");
        //只有仲裁人可以调用此函数
        require(state == EscrowState.DISPUTED, "No dispute to resolve");
        //只有在我们处于争议中时才允许

        state = EscrowState.COMPLETE;
        //将托管标记为完成
        if (_releaseToSeller) {
            //如果是 true：卖家获得 ETH
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        } else {
            payable(buyer).transfer(amount);
            // //如果是 false：买家取回他们的 ETH
            emit DisputeResolved(arbiter, buyer, amount);
        }
    }

    function cancelAfterTimeout() external {
        // 如果卖家延迟，买家取消
        require(msg.sender == buyer, "Only buyer can trigger timeout cancellation");
        //只有买家可以取消
        require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel in current state");
        //只有在我们等待交付时
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");
        //检查超时是否已过

        state = EscrowState.CANCELLED;//取消托管
        payable(buyer).transfer(address(this).balance);//退款给买家
        emit EscrowCancelled(buyer);//托管被取消了
        emit DeliveryTimeoutReached(buyer);//原因是交付超时
    }

    function cancelMutual() external {//任何一方在完成前取消
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        //只有买家或卖家可以取消
        require(
            state == EscrowState.AWAITING_DELIVERY || state == EscrowState.AWAITING_PAYMENT,
                        "Cannot cancel now"
        );//保证合约需要处于 等待买家存款 或者等待卖家交付的状态

        EscrowState previousState = state;//存储之前的状态
        state = EscrowState.CANCELLED;//修改状态为取消

        if (previousState == EscrowState.AWAITING_DELIVERY) {//如果买家已经存入eth 退款给买家
            payable(buyer).transfer(address(this).balance);
        }

        emit EscrowCancelled(msg.sender);//发出取消事件
    }

    function getTimeLeft() external view returns (uint256) {//查看剩余时间
        if (state != EscrowState.AWAITING_DELIVERY) return 0;
        //如果我们不在等待交付，提前退出
        if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        //如果超时已经过去，返回 0
        return (depositTime + deliveryTimeout) - block.timestamp;//否则，返回剩余时间
    }
}

