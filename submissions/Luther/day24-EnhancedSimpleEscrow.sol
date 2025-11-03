//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EnhancedSimpleEscrow {
    //定义一个枚举类型 EscrowState，用于表示托管合约当前的状态
    //AWAITING_PAYMENT：等待买家支付
    //AWAITING_DELIVERY：买家已支付，等待确认收货
    //COMPLETE：交易完成
    //DISPUTED：交易争议状态
    //CANCELLED：交易已取消
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }

    //定义三个地址变量
    address public immutable buyer;     //buyer：买家地址
    address public immutable seller;     //seller：卖家地址
    address public immutable arbiter;     //arbiter：仲裁者地址（用于解决争议）
    //immutable 表示这些变量在部署后不可修改

    //定义合约的关键状态变量
    uint256 public amount;     //amount：托管金额（单位 wei）
    EscrowState public state;     //state：当前托管状态
    uint256 public depositTime;     //depositTime：买家付款的时间戳
    uint256 public deliveryTimeout;     //deliveryTimeout：超时时间限制（单位秒）

    //事件允许外部监听（如 DApp 前端）捕获链上行为
    event PaymentDeposited(address indexed buyer, uint256 amount);     //事件：买家已支付
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);     //事件：买家确认交付并支付给卖家
    event DisputeRaised(address indexed initiator);     //事件：买家或卖家提出争议
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);     //事件：仲裁者解决争议，并将资金转给某方
    event EscrowCancelled(address indexed initiator);     //事件：托管被取消
    event DeliveryTimeoutReached(address indexed buyer);     //事件：超时触发，买家可取消

    //初始化卖家、仲裁者及交付超时时间
    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        //检查传入的 _deliveryTimeout 是否大于 0，否则回退
        require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");
        buyer = msg.sender;     //将部署合约的人（msg.sender）设为买家
        seller = _seller;     //把函数参数 _seller 赋值给 seller 变量，即卖家的地址是由部署着在部署时指定的
        arbiter = _arbiter;     //把仲裁者地址 _arbiter 写入到 arbiter 变量
        state = EscrowState.AWAITING_PAYMENT;     //把合约当前状态设置为 “等待付款” 状态
        deliveryTimeout = _deliveryTimeout;     //保存交付超时时间（秒数）
    }
 
    //定义一个特殊函数，当合约收到直接转账（没有调用任何函数）时会执行
    receive() external payable {
        //拒绝所有直接支付交易
        revert("Direct payments not allowed");
    }

    //买家通过该函数向合约转账（即托管资金）
    function deposit() external payable {
        //确保只有买家能调用此函数
        require(msg.sender == buyer, "Only buyer can deposit");
        //只有在“等待付款”状态下才能付款
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid");
        //付款金额必须大于 0
        require(msg.value > 0, "Amount must be greater than zero");

        //保存付款金额
        amount = msg.value;
        //状态变为“等待交付”
        state = EscrowState.AWAITING_DELIVERY;
        //记录付款时间
        depositTime = block.timestamp;
        //触发事件 PaymentDeposited，通知链上有付款发生
        emit PaymentDeposited(buyer, amount);
    }

    function confirmDelivery() external {
        require(msg.sender == buyer, "Only buyer can confirm");
        require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");

        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    //买家调用确认收货并释放资金给卖家
    function raiseDispute() external {
        //限制：只有买家能确认收货
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        //必须在等待交付阶段才能确认
        require(state == EscrowState.AWAITING_DELIVERY, "Can't dispute now");

        //改变状态为“已完成”
        state = EscrowState.DISPUTED;
        //发出交付确认事件，链上记录该交易已完成
        emit DisputeRaised(msg.sender);
    }
    
    //在争议状态下决定把托管金额释放给卖家或退还给买家
    function resolveDispute(bool _releaseToSeller) external {
        //检查调用者是否为合约中设置的 arbiter（仲裁者）
        require(msg.sender == arbiter, "Only arbiter can resolve");
        //确保当前合约状态是 DISPUTED，即有未决争议可以处理
        require(state == EscrowState.DISPUTED, "No dispute to resolve");

        //把合约状态更新为 COMPLETE（表示争议已解决、流程结束）
        state = EscrowState.COMPLETE;
        //开始一个条件分支。_releaseToSeller 是传入 resolveDispute 的布尔参数
        //当它为 true 时，执行 { ... } 中的语句（也就是把钱给卖家）；否则执行 else 分支（把钱退回买家）
        if (_releaseToSeller) {
            //把合约存储的 amount（以 wei 为单位）立即发送给 seller 地址
            payable(seller).transfer(amount);
            //触发事件 DisputeResolved，把仲裁者地址、接收者（此处为 seller）与金额记录到链上日志中
            emit DisputeResolved(arbiter, seller, amount);
        } else {
            //将 amount wei 发送回 buyer
            payable(buyer).transfer(amount);
            //当退回买家时触发事件，记录仲裁者、接收者（此处为 buyer）和金额
            emit DisputeResolved(arbiter, buyer, amount);
        }
    }

    //定义 cancelAfterTimeout 函数，买家可在超时后调用以取消交易并取回款项
    function cancelAfterTimeout() external {
        //权限检查：只有 buyer 能调用这个函数
        require(msg.sender == buyer, "Only buyer can trigger timeout cancellation");
        //状态检查：仅在 AWAITING_DELIVERY（买家已付款、等待交付）时允许取消
        require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel in current state");
        //检查当前时间是否已达到或超过 depositTime + deliveryTimeout（即交付超时）
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");

        //将合约状态设置为 CANCELLED，标记交易被取消
        state = EscrowState.CANCELLED;
        //合约当前全部余额 (address(this).balance) 转到 buyer
        payable(buyer).transfer(address(this).balance);
        //发出 EscrowCancelled 事件，记录是谁触发取消
        emit EscrowCancelled(buyer);
        //发出 DeliveryTimeoutReached 事件，专门用于标识由超时触发的取消
        emit DeliveryTimeoutReached(buyer);
    }

    //定义 cancelMutual 函数，供买家或卖家在双方同意的情况下取消托管
    function cancelMutual() external {
        //权限检查：只有 buyer 或 seller 可以调用此函数
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        //状态校验：只有在尚未完成流程（还未付款或已付款但尚未交付）时允许协商取消
        require(
            state == EscrowState.AWAITING_DELIVERY || state == EscrowState.AWAITING_PAYMENT,
            "Cannot cancel now"
        );

        //将当前 state 缓存到局部变量 previousState，以便后面判断是否需要退款
        EscrowState previousState = state;
        //把当前状态写为 CANCELLED
        state = EscrowState.CANCELLED;
        
        //如果先前状态是 AWAITING_DELIVERY（即买家已经付款），则进入退款逻辑
        if (previousState == EscrowState.AWAITING_DELIVERY) {
            //把合约当前全部余额退还给买家
            payable(buyer).transfer(address(this).balance);
        }

        //发出取消事件，记录最初发起取消的那一方
        emit EscrowCancelled(msg.sender);
    }

    //定义只读函数 getTimeLeft，返回剩余的交付时间（以秒为单位）
    function getTimeLeft() external view returns (uint256) {
        //若当前状态不是 AWAITING_DELIVERY（表示没有计时进行中），直接返回 0
        if (state != EscrowState.AWAITING_DELIVERY) return 0;
        //如果当前时间已经达到或超过到期时间，则返回 0（表示已超时）
        if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        //返回剩余秒数：到期时间 - 当前时间
        return (depositTime + deliveryTimeout) - block.timestamp;
    }
}

