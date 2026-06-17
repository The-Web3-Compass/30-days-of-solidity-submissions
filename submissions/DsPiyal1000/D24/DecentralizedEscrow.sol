// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EnhancedSimpleEscrow {

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;

    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }
    EscrowState public state;

    uint256 public amount;
    uint256 public depositTime;
    uint256 public immutable deliveryTimeout;

    bool private _locked;
    uint256 private constant MAX_TIMEOUT = 365 days;
    uint256 private constant MIN_TIMEOUT = 1 hours;

    uint256 public disputeRaisedTime;
    address public disputeInitiator;

    uint256 private constant EMERGENCY_TIMEOUT = 30 days;

    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator, uint256 timestamp);
    event DisputeResolved(address indexed arbiter, address indexed recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator, string reason);
    event DeliveryTimeoutReached(address indexed buyer);
    event EmergencyUnlockTriggered(address indexed buyer, uint256 amount);

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "Delivery Timeout must be greater than zero");
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

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call");
        _;
    }

    modifier onlyBuyerOrSeller() {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can call");
        _;
    }

    modifier inState(EscrowState _state) {
        require(state == _state, "Invalid state for operation");
        _;
    }

    receive() external payable {
        revert("Direct payments not allowed");
    }

    fallback() external payable {
        revert("Function does not exist");
    }

    function deposit() external payable nonReentrant onlyBuyer inState(EscrowState.AWAITING_PAYMENT) {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);
    }

    function confirmDelivery() external nonReentrant onlyBuyer inState(EscrowState.AWAITING_DELIVERY) {
        state = EscrowState.COMPLETE;
        uint256 amountToSend = amount;

        (bool success, ) = payable(seller).call{value: amountToSend}("");
        require(success, "Transfer failed");
        emit DeliveryConfirmed(buyer, seller, amountToSend);
    }

    function raiseDispute() external onlyBuyerOrSeller inState(EscrowState.AWAITING_DELIVERY) {
        state = EscrowState.DISPUTED;
        disputeRaisedTime = block.timestamp;
        disputeInitiator = msg.sender;

        emit DisputeRaised(msg.sender, block.timestamp);
    }

    function resolveDispute(bool _releaseToSeller) external nonReentrant onlyArbiter inState(EscrowState.DISPUTED) {
        state = EscrowState.COMPLETE;
        address recipient = _releaseToSeller ? seller : buyer;
        uint256 amountToSend = amount;

        (bool success, ) = payable(recipient).call{value: amountToSend}("");
        require(success, "Transfer failed");
        emit DisputeResolved(arbiter, recipient, amountToSend);
    }

    function cancelAfterTimeout() external nonReentrant onlyBuyer inState(EscrowState.AWAITING_DELIVERY) {
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");

        state = EscrowState.CANCELLED;
        uint256 amountToReturn = address(this).balance; 

        (bool success, ) = payable(buyer).call{value: amountToReturn}("");
        require(success, "Transfer failed");
        emit EscrowCancelled(buyer, "Delivery timeout reached");
        emit DeliveryTimeoutReached(buyer);
    }

    function cancelMutual() external nonReentrant onlyBuyerOrSeller {
        require(state == EscrowState.AWAITING_DELIVERY || state == EscrowState.AWAITING_PAYMENT, "Cannot cancel in current state");

        EscrowState previousState = state;
        state = EscrowState.CANCELLED;

        if(previousState == EscrowState.AWAITING_DELIVERY) {
            uint256 amountToReturn = address(this).balance;
            (bool success, ) = payable(buyer).call{value: amountToReturn}("");
            require(success, "Transfer failed");
        }
        emit EscrowCancelled(msg.sender, "Mutual cancellation");
    }

    function emergencyUnlock() external nonReentrant onlyBuyer {
        require(state == EscrowState.AWAITING_DELIVERY || state == EscrowState.DISPUTED, "Invalid state for emergency unlock");
        require(block.timestamp >= depositTime + EMERGENCY_TIMEOUT, "Emergency timeout not reached");

        state = EscrowState.CANCELLED;
        uint256 amountToReturn = address(this).balance;

        (bool success, ) = payable(buyer).call{value: amountToReturn}("");
        require(success, "Emergency transfer failed");
        emit EmergencyUnlockTriggered(buyer, amountToReturn);
        emit EscrowCancelled(buyer, "Emergency unlock");
    }

    function getTimeLeft() external view returns(uint256) {
        if(state != EscrowState.AWAITING_DELIVERY) return 0;
        if(block.timestamp >= depositTime + deliveryTimeout) return 0;
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