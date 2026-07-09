// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//相当于合约部署人就是买家，她可以同时对好几个商品进行购买，她部署的合约数量就是她购买商品的数量（用这个托管协议）
contract EnhancedSimpleEscrow{
    enum Escrowstate {// 托管合约的状态管理
        AWAITING_PAYMENT,//等待付款
        AWAITING_DELIVERY,//等待交付
        COMPLETE,//完成
        DISPUTED,//争议中
        CANCELLED//已取消
    }
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    Escrowstate public currentState;
    
    // mapping (address => uint256) userBalances;//用户存钱其实好像只是一个用户

    uint256 public amount;
    uint256 public depositTime;//付款时间
    uint256 public deliveryTimeout;//卖家交付窗口期

    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed  initiator);//任何一个人都可以提前争议
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);//仲裁结果谁获得了钱和金额
    event EscrowCancelled(address indexed initiator);//托管被取消，超时或者相互协议取消
    event DeliveryTimeoutReached(address indexed buyer);//超时取消！

    
    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout){
        require(_deliveryTimeout>0, "Delievery timeout must be greater than zero");
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        currentState = Escrowstate.AWAITING_PAYMENT;
        deliveryTimeout = _deliveryTimeout;
    }
    
    modifier onlyArbiter(){
        require(msg.sender == arbiter, "Not arbiter");
        _;
    }
    modifier onlyBuyer(){
        require(msg.sender == buyer, "Only buyer can do");
        _;
    }
    
    receive() external payable {
        revert("Direct payment not allowed");
     }

    // 基本业务逻辑
    // 存钱
    function deposit() external payable onlyBuyer{
        require(currentState == Escrowstate.AWAITING_PAYMENT, "Incorrect State");        
        require(msg.value > 0, "Not zero");

        amount = msg.value;
        currentState = Escrowstate.AWAITING_DELIVERY;//状态转换
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);
    }

    // 确认收货
     function confirmDelivery() external onlyBuyer{
        require(currentState == Escrowstate.AWAITING_DELIVERY, "Not in delivery state");

        currentState = Escrowstate.COMPLETE;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer, seller, amount);

    }

    // 获取余额
    function getBalance() public view returns(uint256){
        return amount;
    }

    function getState() public view returns(Escrowstate){
        return currentState;
    }

    // 提出争议
    function raiseDispute()external{
        require(msg.sender ==buyer || msg.sender==seller, "not authorized");
        require(currentState == Escrowstate.AWAITING_DELIVERY, "Can`t dispute now");
        currentState = Escrowstate.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    // 中立的仲裁人介入解决问题：任何一方提出的争议
    function resolveDispute(bool _releaseToseller)external onlyArbiter{//发送裁判结果
        require(currentState == Escrowstate.DISPUTED, "No dispute to resolve");

        currentState = Escrowstate.COMPLETE;
        if(_releaseToseller){//卖家获得钱
            payable (seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        }else{
            payable (buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount);
        }
    }

    // 相互协定取消
    function cancelMutual() external {
        require(msg.sender == buyer || msg.sender==seller, "not authorized");
        require(currentState == Escrowstate.AWAITING_DELIVERY || currentState == Escrowstate.AWAITING_PAYMENT,"Cannot cancel now");
        Escrowstate previousState = currentState;
        currentState = Escrowstate.CANCELLED;

        if(previousState == Escrowstate.AWAITING_DELIVERY){//付过钱的得退钱
            payable (buyer).transfer(address(this).balance);
        }
        emit EscrowCancelled(msg.sender);

    }

    // 超时取消
    function cancelAfterTimeout() external onlyBuyer{
        require(currentState == Escrowstate.AWAITING_DELIVERY,"cannot cnacel in current state");

        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");
        currentState = Escrowstate.CANCELLED;
        payable (buyer).transfer(amount);
        emit EscrowCancelled(buyer);
        emit DeliveryTimeoutReached(buyer);       

    }

    
}