// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleEscrow{
    enum EscrowState {AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED}

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    uint256 public amount;
    EscrowState public state;
    uint256 public depositTime;
    uint256 deliveryTimeout;

    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(
        address _seller,
        address _arbiter,
        uint256 _deliveryTimeout    //交付期限
    ){
        require(_deliveryTimeout > 0,"");
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
        deliveryTimeout = _deliveryTimeout;
    }

    function deposit() external payable{
        require(state == EscrowState.AWAITING_PAYMENT,"already paid");

        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);

    }

    function confirmDelivery() external payable{
        require(state == EscrowState.AWAITING_DELIVERY,"");
        state = EscrowState.COMPLETE;
        (bool success,) = payable(msg.sender).call{value:msg.value}("");
        require( success,"");
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    function raiseDispute() external{
        require(state == EscrowState.AWAITING_DELIVERY,"");

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool _decision) external{
        require(msg.sender == arbiter,"");
        require(state == EscrowState.DISPUTED,"");

        if(_decision){
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        }
        else{
            payable(buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount);
        }
        state = EscrowState.COMPLETE;
    }

    function cancelAfterTimeout() external{
        require(msg.sender == buyer,"");
        require(block.timestamp >= depositTime + deliveryTimeout);

        state = EscrowState.CANCELLED;
        (bool succ,) = payable(msg.sender).call{value: address(this).balance}("");
        require(succ,"");

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
    
}