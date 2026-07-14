// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedEscrow {
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    uint256 public amount;
    EscrowState public state;

    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
    }

    function deposit() external payable {
        require(msg.sender == buyer && state == EscrowState.AWAITING_PAYMENT, "Invalid deposit");
        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
    }

    function confirmDelivery() external {
        require(msg.sender == buyer && state == EscrowState.AWAITING_DELIVERY, "Invalid confirmation");
        state = EscrowState.COMPLETE;
        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(state == EscrowState.AWAITING_DELIVERY, "Invalid state for dispute");
        state = EscrowState.DISPUTED;
    }

    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter && state == EscrowState.DISPUTED, "Invalid resolution");
        state = EscrowState.COMPLETE;
        (bool success, ) = payable(_releaseToSeller ? seller : buyer).call{value: amount}("");
        require(success, "Transfer failed");
    }
}
