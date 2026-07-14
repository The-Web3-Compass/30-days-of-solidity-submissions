// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EnhancedSimpleEscrow {
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    uint256 public amount;
    EscrowState public state;

    uint256 public immutable deliveryTimeout;
    uint256 public depositTime;

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        deliveryTimeout = _deliveryTimeout;
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
    }

    function deposit() external payable {
        require(msg.sender == buyer && state == EscrowState.AWAITING_PAYMENT);
        amount = msg.value;
        depositTime = block.timestamp;
        state = EscrowState.AWAITING_DELIVERY;
    }

    function cancelDueToTimeout() external {
            require(state == EscrowState.AWAITING_DELIVERY);
            require(block.timestamp >= depositTime + deliveryTimeout);

            state = EscrowState.CANCELLED;

            (bool success, ) = payable(buyer).call{value: amount}("");
            require(success, "Transfer failed");
    }
    
    function confirmDelivery() external {
        require(msg.sender == buyer && state == EscrowState.AWAITING_DELIVERY);
        state = EscrowState.COMPLETE;
        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller);
        state = EscrowState.DISPUTED;
    }

    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter && state == EscrowState.DISPUTED);
        state = EscrowState.COMPLETE;
        (bool success, ) = payable(_releaseToSeller ? seller : buyer).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function cancel() external {
        require(msg.sender == buyer, "Buyers only");
        require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel");
        require(block.timestamp > deliveryTimeout, "Timeout not reached");

        state = EscrowState.CANCELLED;

        (bool success, ) = payable(buyer).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function resolveDisputePartial(uint256 _buyerAmount, uint256 _sellerAmount) external {
        require(msg.sender == arbiter && state == EscrowState.DISPUTED);
        require(_buyerAmount + _sellerAmount == amount);

        state = EscrowState.COMPLETE;
        (bool successBuyer, ) = payable(buyer).call{value: _buyerAmount}("");
        require(successBuyer, "Transfer to buyer failed");
        (bool successSeller, ) = payable(seller).call{value: _sellerAmount}("");
        require(successSeller, "Transfer to seller failed");
    }

    struct Milestone {
        string description;
        uint256 amount;
        bool completed;
    }

    Milestone[] public milestones;

    function completeMilestone(uint256 _index) external {
        require(msg.sender == buyer);
        require(!milestones[_index].completed);

        milestones[_index].completed = true;
        (bool success, ) = payable(seller).call{value: milestones[_index].amount}("");
        require(success, "Transfer failed");
    }
}