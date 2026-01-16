// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EnhancedSimpleEscrow {
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }
    //用 enum 来跟踪交易处于哪个阶段
    
    address public immutable buyer;//这个变量在合约部署时可以设置一次，但部署完成后就永久固定，无法再修改。
    address public immutable seller;
    address public immutable arbiter;

    uint256 public amount;
    EscrowState public state;
    uint256 public depositTime;
    uint256 public deliveryTimeout; // 卖家交付的窗口期（以秒为单位）

    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
        deliveryTimeout = _deliveryTimeout;
    }

    receive() external payable {
        revert("Direct payments not allowed");//revert()会中止交易, 
    }

    //存款（买家将 ETH 锁定到合约中）
    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid");
        require(msg.value > 0, "Amount must be greater than zero");

        amount = msg.value; //将转账金额存在名为 amount 的状态变量中
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);
    }

    function confirmDelivery() external {
        require(msg.sender == buyer, "Only buyer can confirm");
        require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");

        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);//合约从自己账户里转出 amount 给 seller
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(state == EscrowState.AWAITING_DELIVERY, "Can't dispute now");

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool _releaseToSeller) external {//是否把钱释放给卖家
        require(msg.sender == arbiter, "Only arbiter can resolve");
        require(state == EscrowState.DISPUTED, "No dispute to resolve");

        state = EscrowState.COMPLETE;
        if (_releaseToSeller) {
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        } else {
            payable(buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount);
        }
    }

    function cancelAfterTimeout() external {
        require(msg.sender == buyer, "Only buyer can trigger timeout cancellation");
        require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel in current state");
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");

        state = EscrowState.CANCELLED;
        payable(buyer).transfer(address(this).balance);
        emit EscrowCancelled(buyer);
        emit DeliveryTimeoutReached(buyer);
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
