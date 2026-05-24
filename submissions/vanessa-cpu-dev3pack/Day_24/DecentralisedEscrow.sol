// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralisedEscrow {
    enum EscrowState { AWAITING_PATMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    uint256 public amount;
    EscrowState public state;

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
    }

    function deposit() external payable {
        require(msg.sender == buyer && state == EscrowState.AWAITING_PAYMENT);
        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
    }
function confirmDelivery() external {
    require(msg.sender == buyer && state == EscrowState.AWAITING_DELIVERY);
    state = EscrowState.COMPLETE;
    payable(seller).transfer(amount);
}

function raiseDispute() external {
    require(msg.sender == buyer || msg.sender == seller);
    state = EscrowState.DISPUTED;
}

function resolveDispute(bool _releaseToSeller) external {
    require(msg.sender == arbiter && state == EscrowState.DISPUTED);
    state = EscrowState.COMPLETE;
    payable(_releaseToSeller ? seller : buyer).transfer(amount;)
}
}