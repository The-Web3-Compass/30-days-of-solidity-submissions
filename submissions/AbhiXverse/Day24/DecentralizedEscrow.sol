// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

// Decentralized Escrow Contract
contract DecentralizedEscrow {

    // This contract is used to hold funds in escrow until the buyer confirms delivery of the product or service.
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }

    address public immutable buyer;            // The address of the buyer
    address public immutable seller;           // The address of the seller
    address public immutable arbiter;          // The address of the arbiter

    uint256 public amount;                     // The amount of ether held in escrow
    EscrowState public state;                  // The current state of the escrow
    uint256 public depositTime;                // The time when the payment was deposited
    uint256 public deliveryTimeout;            // The time limit for delivery confirmation

    //  event to be emitted when payment is deposited
    event PaymentDeposited(address indexed buyer, uint256 amount);
    
    // event to be emitted when delivery is confirmed
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount );
 
    // event to be emitted when a dispute is raised
    event DisputeRaised(address indexed initiator);

    //  event to be emitted when a dispute is resolved
    event DisputeResolved(address arbiter, address indexed receipent, uint256 amount);

    //  event to be emitted when the delivery timeout is reached
    event DeliveryTimeoutReached(address indexed buyer);
    
    // event to be emitted when the escrow is cancelled
    event EscrowCancelled(address indexed initiator);


    // constructor to initialize the escrow contract
    constructor(address _seller, address _buyer, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "delivert timeout must be zero");
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
        deliveryTimeout = _deliveryTimeout;
    }

    // function to receive ether. This function is not used in this contract.
    receive() external payable {
        revert ("Direct payment not allowed");
    }

    // function to deposit ether into the escrow contract
    function deposit() external payable {
        require(msg.sender == buyer, "only buyer can dopsit");
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid");
        require(msg.value > 0, "amount mush be > 0");

        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);
    }

    // function to confirm delivery of the product or service
    function ConfirmDelivery() external {
        require(msg.sender == buyer, "Only buyer can call this");
        require(state == EscrowState.AWAITING_DELIVERY, "not in delivery state");

        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    //  function to raise a dispute
    function raiseDispute() external {
        require (msg.sender == buyer || msg.sender == seller, "Not authorized");
        require (state == EscrowState.AWAITING_DELIVERY, "can't dispute now");

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    // function to resolve a dispute
    function resolveDispute(bool _releaseToseller) external {
        require (msg.sender == arbiter, "only arbiter can resolve it");
        require (state == EscrowState.DISPUTED,"No dispute to resolve");

        state = EscrowState.COMPLETE;
        if (_releaseToseller) {
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        } 
        else {
            payable(buyer).transfer(address(this).balance);
            emit DisputeResolved (arbiter, buyer, amount);
        }
    }

    // function to cancel the escrow contract after a timeout
    function cancelAfterTimeout() external {
        require (msg.sender == buyer," only buyer can do this");
        require (state == EscrowState.AWAITING_DELIVERY, "cannot cancel in current state");
        require (block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");

        state = EscrowState.CANCELLED;
        payable(buyer).transfer(address(this).balance);
        emit EscrowCancelled(msg.sender);
        emit DeliveryTimeoutReached(buyer);
    }

    // function to cancel the escrow contract by either party
    function CancelMutual() external {
        require (msg.sender == buyer || msg.sender == seller, "Not authorized");
        require (state == EscrowState.AWAITING_DELIVERY, "cannot cancel now");

        EscrowState previousState  = state;
        state = EscrowState.CANCELLED;

        if (previousState == EscrowState.AWAITING_DELIVERY) {
            payable(buyer).transfer(address(this).balance);
        }
        else {
            emit EscrowCancelled (msg.sender);
        }
    }

    //  function to get the timeleft for delivery confirmation
    function getTimeLeft() external view returns (uint256) {
        if (state != EscrowState.AWAITING_DELIVERY) 
        return 0;
        if (block.timestamp >= depositTime + deliveryTimeout)
        return 0;

        return (depositTime + deliveryTimeout) - block.timestamp;         
    }
    
}
