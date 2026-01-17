//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
// This contract can:
// Hold ETH until the buyer confirms delivery;
// Lets either party raise a dispute if things go wrong;
// Allows a neutral arbiter to step in and resolve issues;
// Has built-in timeout logic so the buyer isn't left hanging forever;
// Supports mutual cancellation if both parties agree to call it off.

contract EnhancedSimpleEscrow{
    enum EscrowState{AWAITING_PAYMENT,AWAITING_DELIVERY,COMPLETE,DISPUTED,CANCELLED}

    // "immutable" in variable declaration means that the varaible can be assigned once.
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter; // The arbiter is the trusted third party who resolves disputes.

    uint256 public amount;
    EscrowState public state;
    uint256 public depositTime;
    uint256 public deliveryTimeout; // This is the window(in seconds) the seller has to deliver.

    event PaymentDeposited(address indexed buyer,uint256 amount);
    event DeliveryConfirmed(address indexed buyer,address indexed seller,uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter,address recipient,uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(address _seller,address _arbiter,uint256 _deliveryTimeout){
        require(_deliveryTimeout>0,"Delivery timeout must be greater than zero");
        buyer=msg.sender;
        seller=_seller;
        arbiter=_arbiter;
        state=EscrowState.AWAITING_PAYMENT;
    }

    // It blocks any ETH that someone tries to send without calling the correct function, like "deposit()".
    // By default, any smart contract in Solidity can receive ETH silently, even if the sender doesn't call a specific function.
    // The purepose of "receive()":  this special function is called automatically whenever the contract receives ETH without any data.
    receive() external payable{
        // All of that is skipped if someone send ETH blindly.
        revert("Direct payments not allowed");
    }

    // Buyer sends funds to escrow.
    function deposit() external payable{
        require(msg.sender==buyer,"Only buyer can deposit");
        require(state==EscrowState.AWAITING_PAYMENT,"Already paid");
        require(msg.value>0,"Amount must be greater than zero");

        amount=msg.value;
        state=EscrowState.AWAITING_DELIVERY;
        depositTime=block.timestamp;
        emit PaymentDeposited(buyer,amount);

    }

    // Buyer marks the deal complete.
    function confirmDelivery() external{
        require(msg.sender==buyer,"Only buyer can confirm");
        require(state==EscrowState.AWAITING_DELIVERY,"Not in delivery state");

        state=EscrowState.COMPLETE;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer,seller,amount);


    }

    // Buyer or seller flags a problem
    function raiseDispute() external{
        require(msg.sender==buyer||msg.sender==seller,"Not authorized");
        require(state==EscrowState.AWAITING_DELIVERY,"Can't dispute now");

        state=EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    // Arbiter decides the outcome
    function resolveDispute(bool _releaseToSeller) external{
        require(msg.sender==arbiter,"Only arbiter can resolve");
        require(state==EscrowState.DISPUTED,"No dispute to resolve");

        state==EscrowState.COMPLETE;
        if(_releaseToSeller){
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter,seller,amount);
        }
        else{
            payable(buyer).transfer(amount);
            emit DisputeResolved(arbiter,buyer,amount);
        }

    }

    // Buyer cancels f seller delays
    function cancelAfterTimeout() external{
        require(msg.sender==buyer,"Only buyer can trigger timeout cancellation");
        require(state==EscrowState.AWAITING_DELIVERY,"Cannot cancel in current state");
        require(block.timestamp>=depositTime+deliveryTimeout,"Timeout not reached");

        state=EscrowState.CANCELLED;
        payable(buyer).transfer(address(this).balance);
        emit EscrowCancelled(buyer);
        emit DeliveryTimeoutReached(buyer);

    }

    // Either party cancels before completion
    function cancelMutual() external{
        require(msg.sender==buyer||msg.sender==seller,"Not authorized");
        require(state==EscrowState.AWAITING_DELIVERY||state==EscrowState.AWAITING_PAYMENT,"Cannot cancel now");

        EscrowState previousState=state;
        state=EscrowState.CANCELLED;

        if(previousState==EscrowState.AWAITING_DELIVERY){
            payable(buyer).transfer(address(this).balance);
        }

        emit EscrowCancelled(msg.sender);

    }

    // View how much time remains
    function getTimeLeft() external view returns (uint256){
        if(state!=EscrowState.AWAITING_DELIVERY) return 0;
        if(block.timestamp>=depositTime+deliveryTimeout) return 0;
        return (depositTime+deliveryTimeout)-block.timestamp;

    }



}