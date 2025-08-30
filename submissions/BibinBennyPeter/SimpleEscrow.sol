pragma solidity ^0.8.20;
// SPDX-License-Identifier: MIT

contract SimpleEscrow {
   address public buyer;
   address public seller;
   address public arbiter;

   uint256 public amount;
   uint256 public timeout;
   enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELED }
   State public state;

   event PaymentDeposited(address indexed buyer, uint256 amount);
   event DeliveryConfirmed(address indexed buyer);
   event DisputeRaised(address indexed disputer);
   event EscrowCompleted(address indexed buyer, address indexed seller);
   event EscrowCanceled(address indexed canceler);

    constructor(address _seller, address _arbiter, uint256 _timeoutInDays) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        timeout = _timeoutInDays;
        state = State.AWAITING_PAYMENT;
    }
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }

    function deposit() external payable onlyBuyer {
        require(state == State.AWAITING_PAYMENT, "Payment already made or escrow completed");
        require(msg.value > 0, "Deposit amount must be greater than zero");
        amount = msg.value;
        state = State.AWAITING_DELIVERY;

        timeout = block.timestamp + (timeout * 1 days);

        emit PaymentDeposited(buyer, amount);
      
    }

    function confirmDelivery() external onlyBuyer {
        require(state == State.AWAITING_DELIVERY, "Delivery not expected at this stage");

        state = State.COMPLETE;
        payable(seller).transfer(amount);

        emit DeliveryConfirmed(buyer);
        emit EscrowCompleted(buyer, seller);
    }

    function raiseDispute() external {
      require (msg.sender == buyer || msg.sender == arbiter, "Only buyer or arbiter can raise a dispute");

      state = State.DISPUTED;
      emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool _refundBuyer) external {
        require(msg.sender == arbiter, "Only arbiter can resolve disputes");
        require(state == State.DISPUTED, "No dispute to resolve");

        if (_refundBuyer) {
            payable(buyer).transfer(amount);
        } else {
            payable(seller).transfer(amount);
        }

        state = State.COMPLETE;
        emit EscrowCompleted(buyer, seller);
    }

    function cancelEscrow() external onlyBuyer{
      require(state != State.COMPLETE || state != State.DISPUTED, "Cannot cancel completed or disputed escrow");

      if (state == State.AWAITING_PAYMENT) {
          state = State.CANCELED;
          emit EscrowCanceled(buyer);
      } else if (state == State.AWAITING_DELIVERY) {
          require(block.timestamp > timeout, "Cannot cancel before timeout");
          state = State.CANCELED;
          payable(buyer).transfer(amount);
          emit EscrowCanceled(buyer);
      }
    }

}

