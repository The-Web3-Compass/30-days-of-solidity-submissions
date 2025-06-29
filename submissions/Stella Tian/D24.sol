// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract decentralise{
enum escrowstate {
    AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED
}
address public immutable buyer;
address public immutable seller;
address public immutable arbiter;
uint256 public amount;
escrowstate public state;
uint256 public deposittime;
uint256 public deliverytimeout;
event paymentdeposited(address indexed buer, uint256 amount);
event deliveryconfirmed(address indexed buyer, address indexed seller, uint256 amount);
event disputeraised(address indexed initiator);
event disputeresolved(address indexed arbiter, address recipient, uint256 amount);
event escrowcancelled(address indexed initiator);
event deliverytimeoutreach(address indexed buyer);
constructor(address _seller, address _arbiter, uint256 _deliverytimeout){
    require(_deliverytimeout >0, "invalid");
    buyer = msg.sender;
    seller = _seller;
    arbiter = _arbiter;
    state = escrowstate.AWAITING_PAYMENT;
    deliverytimeout = _deliverytimeout;
}
  receive() external payable{
    revert("not allowed");
  }
  function deposit() external payable{
    require(msg.sender == buyer, "invalid");
    require(state == escrowstate.AWAITING_PAYMENT, "invalid");
    require(msg.value >0, "invalid");
    amount = msg.value;
    state = escrowstate.AWAITING_DELIVERY;
    deposittime = block.timestamp;
    emit paymentdeposited(buyer, amount);
  }
  function confirmdelivery() external {
    require(msg.sender == seller, "invalid");
 require(state == escrowstate.AWAITING_DELIVERY, "invalid");
 state = escrowstate.COMPLETE;
 payable(seller).transfer(amount);
 emit deliveryconfirmed(buyer, seller, amount);
  }
  function raisedispute() external {
    require(msg.sender == buyer || msg.sender == seller, "invalid");
    require(state == escrowstate.AWAITING_DELIVERY,"inlivd");
    state = escrowstate.DISPUTED;
    emit disputeraised(msg.sender);
  }
  function resolvedispute(bool _releasetoseller) external{
    require(msg.sender == arbiter, "invalid");
    require(state == escrowstate.DISPUTED, "invalid");
    state = escrowstate.COMPLETE;
    if (_releasetoseller){
    payable(seller).transfer(amount);
    emit disputeresolved(arbiter, seller, amount);
    } else{
        payable(buyer).transfer(amount);
        emit disputeresolved(arbiter, buyer, amount);
    }
  }
  function cancelafertimeout() external {
    require(msg.sender == buyer, "invalid");
    require(state == escrowstate.AWAITING_DELIVERY, "invalid");
    require(block.timestamp >= deposittime +deliverytimeout, "invalid");
    state = escrowstate.CANCELLED;
    payable(buyer).transfer(address(this).balance);
    emit escrowcancelled(buyer);
    emit deliverytimeoutreach(buyer);
  }
  function cancelmutual() external {
    require(msg.sender == buyer || msg.sender ==seller, "invalid");
    require(state == escrowstate.AWAITING_DELIVERY || state == escrowstate.AWAITING_PAYMENT, "invalid");
    escrowstate previousstate = state;
    state = escrowstate.CANCELLED;
    if(previousstate == escrowstate.AWAITING_DELIVERY){
        payable(buyer).transfer(address(this).balance);
    }
    emit escrowcancelled(msg.sender);
  }
  function gettimeleft() external view returns(uint256){
    if (state != escrowstate.AWAITING_DELIVERY) return 0;
    return (deposittime + deliverytimeout) - block.timestamp;
  }
}