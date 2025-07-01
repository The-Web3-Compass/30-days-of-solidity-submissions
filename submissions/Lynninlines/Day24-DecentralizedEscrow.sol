// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedEscrow {
    
    address public buyer;
    address public seller;
    address public arbiter;
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETED, REFUNDED, DISPUTED }
    State public currentState;
    uint256 public constant TIMEOUT_DURATION = 30 days;
    uint256 public timeout;
    event FundsDeposited(uint256 amount);
    event FundsReleased(uint256 amount);
    event FundsRefunded(uint256 amount);
    event DisputeResolved(address winner, uint256 amount);
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call");
        _;
    }

    modifier inState(State expectedState) {
        require(currentState == expectedState, "Invalid state");
        _;
    }

    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        currentState = State.AWAITING_PAYMENT;
    }

    function deposit() external payable onlyBuyer inState(State.AWAITING_PAYMENT) {
        require(msg.value > 0, "Must send ETH");
        currentState = State.AWAITING_DELIVERY;
        timeout = block.timestamp + TIMEOUT_DURATION; 
        emit FundsDeposited(msg.value);
    }

    function confirmDelivery() external onlyBuyer inState(State.AWAITING_DELIVERY) {
        currentState = State.COMPLETED;
        payable(seller).transfer(address(this).balance);
        emit FundsReleased(address(this).balance);
    }

    function requestRefund() external onlyBuyer inState(State.AWAITING_DELIVERY) {
        require(block.timestamp < timeout, "Use timeoutRefund");
        currentState = State.REFUNDED;
        payable(buyer).transfer(address(this).balance);
        emit FundsRefunded(address(this).balance);
    }

    function timeoutRefund() external inState(State.AWAITING_DELIVERY) {
        require(block.timestamp >= timeout, "Timeout not reached");
        currentState = State.REFUNDED;
        payable(buyer).transfer(address(this).balance);
        emit FundsRefunded(address(this).balance);
    }

    function raiseDispute() external {
        require(
            msg.sender == buyer || msg.sender == seller,
            "Only buyer/seller"
        );
        require(currentState == State.AWAITING_DELIVERY, "Invalid state");
        currentState = State.DISPUTED;
    }

    function resolveDispute(
        address payable winner, 
        uint256 buyerAmount, 
        uint256 sellerAmount
    ) external onlyArbiter inState(State.DISPUTED) {
        require(
            buyerAmount + sellerAmount == address(this).balance,
            "Invalid amounts"
        );
        
        currentState = State.COMPLETED;
        payable(buyer).transfer(buyerAmount);
        payable(seller).transfer(sellerAmount);
        
        emit DisputeResolved(winner, winner == buyer ? buyerAmount : sellerAmount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
