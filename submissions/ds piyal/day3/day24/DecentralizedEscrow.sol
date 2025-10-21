// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EnhancedSimpleEscrow{

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;

    enum EscrowState{ AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }
    EscrowState public state;
    
    uint256 public amount;
    uint256 public depositTime;
    uint256 public deliveryTimeout;

    bool private _locked;
    uint256 private constant MAX_TIMEOUT = 365 days; 
    uint256 private constant MIN_TIMEOUT = 1 hours;

    uint256 public disputeRaisedTime;
    address public disputeInitiator;
    
    uint256 private constant EMERGENCY_TIMEOUT = 30 days;
    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator, uint256 timestamp);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout){
        require(_deliveryTimeout > 0,"Delivery Timeout must be greater than zero");
        require(_seller != address(0) && _arbiter != address(0), "Invalid address");
        require(_seller != msg.sender && _arbiter != msg.sender && _seller != _arbiter, "Addresses must be unique");
        
        require(_deliveryTimeout >= MIN_TIMEOUT && _deliveryTimeout <= MAX_TIMEOUT, "Invalid timeout range");
        
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
        deliveryTimeout = _deliveryTimeout;
    }

    modifier nonReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    receive() external payable {
        revert("Direct payments not allowed");
    }

    function deposit() external payable nonReentrant {
        require(msg.sender == buyer,"Only buyer can deposit");
        require(state == EscrowState.AWAITING_PAYMENT,"Already paid");
        require(msg.value > 0,"Deposit amount must be greater than zero");

        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);
    }

    function confirmDelivery() external nonReentrant {
        require(msg.sender == buyer,"only buyer can confirm");
        require(state == EscrowState.AWAITING_DELIVERY,"Not waiting for delivery");

        state = EscrowState.COMPLETE;
        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Transfer failed");
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller,"Only buyer or seller can dispute");
        require(state == EscrowState.AWAITING_DELIVERY,"Not waiting for delivery");

        state = EscrowState.DISPUTED;
        disputeRaisedTime = block.timestamp;
        disputeInitiator = msg.sender;       
        
        emit DisputeRaised(msg.sender, block.timestamp);
    }

    function resolveDispute(bool _releaseToSeller) external nonReentrant {
        require(msg.sender == arbiter,"Only arbiter can resolve");
        require(state == EscrowState.DISPUTED,"Not disputed yet");

        state = EscrowState.COMPLETE;
        
        if(_releaseToSeller){
            (bool success, ) = payable(seller).call{value: amount}("");
            require(success, "Transfer failed");
            emit DisputeResolved(arbiter, seller, amount);
        } else {
            (bool success, ) = payable(buyer).call{value: amount}("");
            require(success, "Transfer failed");
            emit DisputeResolved(arbiter, buyer, amount);
        }
    }

    function cancelAfterTimeout() external nonReentrant {
        require(msg.sender == buyer,"only buyer can trigger timeout cancellation");
        require(state == EscrowState.AWAITING_DELIVERY,"Not waiting for delivery");
        require(block.timestamp >= depositTime + deliveryTimeout,"Timeout not reached");

        state = EscrowState.CANCELLED;
        (bool success, ) = payable(buyer).call{value: address(this).balance}("");
        require(success, "Transfer failed");
        emit EscrowCancelled(buyer);
        emit DeliveryTimeoutReached(buyer);
    }

    function cancelMutual() external nonReentrant {
        require(msg.sender == buyer || msg.sender == seller,"not authorized");
        require(state == EscrowState.AWAITING_DELIVERY || state == EscrowState.AWAITING_PAYMENT,"can't cancel now");
        EscrowState previousState = state;
        state = EscrowState.CANCELLED;

        if(previousState == EscrowState.AWAITING_DELIVERY){
            (bool success, ) = payable(buyer).call{value: address(this).balance}("");
            require(success, "Transfer failed");
        }
        emit EscrowCancelled(msg.sender);
    }

    function emergencyUnlock() external nonReentrant {
        require(msg.sender == buyer, "Only buyer can emergency unlock");
        require(state == EscrowState.AWAITING_DELIVERY || state == EscrowState.DISPUTED, "Invalid state");
        require(block.timestamp >= depositTime + EMERGENCY_TIMEOUT, "Emergency timeout not reached");
        
        state = EscrowState.CANCELLED;
        (bool success, ) = payable(buyer).call{value: address(this).balance}("");
        require(success, "Emergency transfer failed");
        emit EscrowCancelled(buyer);
    }

    function getTimeLeft() external view returns(uint256) {
        if(state != EscrowState.AWAITING_DELIVERY) return 0;
        if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        return(depositTime + deliveryTimeout) - block.timestamp;
    }

    function getDisputeInfo() external view returns(uint256 raisedTime, address initiator, uint256 timeElapsed) {
        return (disputeRaisedTime, disputeInitiator, disputeRaisedTime > 0 ? block.timestamp - disputeRaisedTime : 0);
    }

    function getContractDetails() external view returns(
        EscrowState currentState,
        uint256 escrowAmount,
        uint256 timeDeposited,
        uint256 timeout
    ) {
        return (state, amount, depositTime, deliveryTimeout);
    }

    function getEmergencyTimeLeft() external view returns(uint256) {
        if(state != EscrowState.AWAITING_DELIVERY && state != EscrowState.DISPUTED) return 0;
        if(depositTime == 0) return 0;
        if(block.timestamp >= depositTime + EMERGENCY_TIMEOUT) return 0;
        return (depositTime + EMERGENCY_TIMEOUT) - block.timestamp;
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }
}