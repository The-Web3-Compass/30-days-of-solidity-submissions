//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title DecentralizedEscrow
 * @author Eric (https://github.com/0xxEric)
 * @notice A platform for escrow funds in transactions
 * @custom:project 30-days-of-solidity-submissions: Day24
 */

contract DecentralizedEscrow{
    enum State { Created, Delivered,Completed, Disputed, Resolved }
    address public admin;
    uint32 public platformFee=2; // fee percentage for platform, inital default value is 2%.
    uint32 public arbFee=3;     // fee percentage for arbitration, inital default value is 3%.
    uint32 deliveryTime=200;
    uint32 confirmTime=100;
    uint32 disputeTime=300;


    struct Order{
        address buyer;
        address seller;
        address arbitrator;
        uint32 Id; // The Id of Order
        uint256 amount;
        State state;
        uint256 creationTime;
        uint256 deliveryDeadline;
        uint256 confirmationDeadline;
        uint256 disputeDeadline;
        string deliveryProofCID;
    }

    mapping(uint32 => Order) public orders;
    uint32 public orderCount;
    mapping(address => bool) public arbitrators; 
    address[] historyArbitrators;

    event OrderCreatedAndDeposit(uint32 orderId, address buyer,address seller, uint256 amount);
    event ItemDelivered(uint32 orderId, string proofCID);
    event ItemConfirmed(uint32 orderId, address seller,uint256 amount)
    event DisputeRaised(uint32 orderId, address buyer,uint256 amount);
    event DisputionResolve(uint32 orderId,address buyer,uint256 buyerAmount,address seller,uint256 sellerAmount);

    constructor() {
        admin = msg.sender;
    }

    modifier Onlyadmin() {
        require(msg.sender == admin, "Only admin can transfer the authority ");
        _;
    }

    modifier nonReentrant() {
        require(locked == 0, "No reentrancy allowed");
        locked = 1;
        _;
        locked = 0;
    }

    ///Setting
    function configureSet(uint32 _platformFee,uint32 _confirmTime, uint32 _deliveryTime, uint32 _disputeTime) external Onlyadmin{
        require(_platformFee>0&&_platformFee<100,"Wrong feepercent");
        require(_confirmTime>10 && _deliveryTime>10 && _disputeTime>10,"Wong time set");
        platformFee=_platformFee;
        confirmTime=_confirmTime;
        disputeTime=_disputeTime;
    }

    function transferAdmin(address newadmin) external Onlyadmin{
        require(newadmin != address(0), "wrong address");
        admin==newadmin;
    }

    function addArbitrator(address newArbitrator) external Onlyadmin{
        require(newArbitrator != address(0), "wrong address");
        arbitratorCount++;
        arbitrators[newArbitrator] = true;
        historyArbitrators.push(newArbitrator);
    }

    function removeArbitrator(address arbitrator) external Onlyadmin{
        require(arbitrator != address(0), "wrong address");
        arbitrators[arbitrator] = false;
    }
    

    ///Transcation
    function createOrderAndDeposit(address _seller,uint256 _amount,uint32 _arbitrator) external payable{
        require(msg.value == _amount, "Incorrect amount");
        require(seller != address(0), "Wrong address");
        require(arbitrators[arbitrator]==true,"Wrong arbitrator");
        orderCount++;
        orderId=orderCount;
        uint256 ctime=block.timestamp;
        uint256 dtime=ctime+deliveryTime;
        orders[orderId]=Order({
            buyer:msg.sender,
            seller:_seller,
            arbitrator:_arbitrator,
            Id=orderId,
            amount=_amount,
            state:State.Created,
            creationTime:ctime,
            deliveryDeadline:dtime,
            confirmationDeadline:0,
            disputeDeadline:0,
            deliveryProofCID:""
        })
        emit OrderCreatedAndDeposit(orderId, msg.sender, seller, amount);
    }

    function isOrderExist(uint orderId) internal view returns (bool) {
    return orders[orderId].state != State.None;  
}

    function deliverItem(uint orderId, string calldata proofCID) external {
        require(isOrderExist(orderId),"Order not exist");
        Order storage order = orders[orderId];
        require(order.state == State.Created && msg.sender == order.seller, "Invalid action");
        order.state = State.Delivered;
        order.deliveryProofCID = proofCID;  // save the CID
        order.confirmationDeadline=block.timestamp+confirmTime;
        emit ItemDelivered(orderId, proofCID);
    }

    function checkDeliveryTimeout(uint orderId) external {
        require(isOrderExist(orderId),"Order not exist");
        Order storage order = orders[orderId];
        require(order.buyer==msg.sender && order.state == State.Created, "Invalid state");
        if (block.timestamp > order.deliveryDeadline) {
            order.state = State.Disputed; //set the order into dispution
            emit DisputeRaised(orderId, msg.sender,order.amount);
        }
    }

    function confirmDelivery(uint orderId) external nonReentrant {
        require(isOrderExist(orderId),"Order not exist");
        Order storage order = orders[orderId];
        require(order.state == State.Delivered && msg.sender == order.buyer, "Invalid action");
        uint256 payamount=order.amount*(100-platformFee)/100;
        order.state = State.Completed;
        (bool success, ) = payable(order.seller).call{value: payamount, gas: 2000}("");
        require(success, "Transfer failed");
        emit ItemConfirmed(orderId,order.seller,payamount);
    }

    function disputionResolve(uint orderId,uint256 amount, bool IsSellerConfirm,bool IsBuyerConfirm) external nonReentrant {
        require(isOrderExist(orderId),"Order not exist");
        Order storage order = orders[orderId];
        require(order.state == State.Disputed, "Invalid action");
        uint256 netAmount=order.amount*(100-platformFee-arbFee)/100;  //remaining amount after reduce the Fee
        uint256 arbFeeAmount=arbFee*order.amount/100;
        requier(amount>=0&&amount<=netAmount,"wrong amount"); //Amount of arbitration,means the amount buyer should pay for the order.
        order.state=State.Resolved;
        if(IsSellerConfirm && IsBuyerConfirm){ //If both of buyer and seller agree to the arbitration result
            (bool success1, ) = payable(order.seller).call{value: amount, gas: 2000}("");
            (bool success2, ) = payable(order.buyer).call{value: (netAmount-amount), gas: 2000}("");
            (bool success3, ) = payable(order.arbitrator).call{value: arbFeeAmount, gas: 2000}("");
            require(success1 && success2 && success3, "Transfer failed");
            emit DisputionResolve(orderId,order.buyer,(netAmount-amount),order.seller,amount);
        }
        else{ //If any of them disagree,then 20% leave in platform,30% give back to buyer.
           uint256 buyerAmount=netAmount/2;
           uint256 sellerAmount=netAmount*3/10;
            (bool success1, ) = payable(order.buyer).call{value: buyerAmount, gas: 2000}("");
            (bool success1, ) = payable(order.seller).call{value: sellerAmount, gas: 2000}("");
            (bool success3, ) = payable(order.arbitrator).call{value: arbFeeAmount, gas: 2000}("");
            require(success1 && success2 && success3, "Transfer failed");
            emit DisputionResolve(orderId,order.buyer,buyerAmount,order.seller,sellerAmount);
        }
    }

    function confirmTimeout(uint orderId) external nonReentrant{
        require(isOrderExist(orderId),"Order not exist");
        requier()
        Order storage order = orders[orderId];        
        if(order.state == State.Delivered && block.timestamp>order.confirmationDeadline){
            order.state==State.Completed; // then transfer to seller directly
            uint256 payamount=order.amount*(100-platformFee)/100;
            (bool success, ) = payable(order.seller).call{value: payamount, gas: 2000}("");
            require(success, "Transfer failed");
        }
        else{
            revert("Wrong state");
        }
    }
}
