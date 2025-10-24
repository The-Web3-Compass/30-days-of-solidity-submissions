// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title DecentralisedEscrow
 * @dev Build a secure system for holding funds until conditions are met.
 * You'll learn how to manage payments and handle disputes.
 * It's like a digital middleman for secure transactions, demonstrating secure conditional payments.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 24
 */
contract DecentralisedEscrow {
    enum State {
        WAIT_PAY,
        WAIT_DELIVER,
        COMPLETED,
        SELLER_DISPUTED,
        BUYER_DISPUTED,
        JUDGED_FOR_SELLER,
        JUDGED_FOR_BUYER,
        TIMED_OUT
    }

    State public state;
    address public immutable buyer;
    address public immutable seller;
    address public immutable judge;
    uint256 public immutable value;
    uint256 public immutable duration;
    uint256 public depositTs;

    constructor(
        address _buyer,
        address _seller,
        address _judge,
        uint256 _value,
        uint256 _duration
    ) {
        require(
            _buyer != address(0x00) &&
            _seller != address(0x00) &&
            _judge != address(0x00),
            "null addresses not allowed"
        );
        require(_value > 0, "value cannot be zero");
        require(_duration > 0, "duration cannot be zero");
        state = State.WAIT_PAY;
        buyer = _buyer;
        seller = _seller;
        judge = _judge;
        value = _value;
        duration = _duration;
    }

    modifier onlyAddress(address a) {
        require(msg.sender == a, "this address not allowed");
        _;
    }

    modifier onlyState(State s) {
        require(state == s, "this state not allowed");
        _;
    }

    function buyerDeposit()
        public payable onlyAddress(buyer) onlyState(State.WAIT_PAY)
    {
        require(msg.value == value, "amount mismatch");
        depositTs = block.timestamp;
        state = State.WAIT_DELIVER;
    }

    receive() external payable {
        buyerDeposit();
    }

    function buyerDeliveryReceived()
        public onlyAddress(buyer) onlyState(State.WAIT_DELIVER)
    {
        state = State.COMPLETED;
        (bool transferSuccess, ) = payable(seller).call{ value: value }("");
        require(transferSuccess, "transfer failed");
    }

    function sellerDispute()
        public onlyAddress(seller) onlyState(State.WAIT_DELIVER)
    {
        state = State.SELLER_DISPUTED;
    }

    function buyerDispute()
        public onlyAddress(buyer) onlyState(State.WAIT_DELIVER)
    {
        state = State.SELLER_DISPUTED;
    }

    function judgeRuling(bool inFavourOfBuyer)
        public onlyAddress(judge)
    {
        require(
            state == State.SELLER_DISPUTED ||
            state == State.BUYER_DISPUTED,
            "this state not allowed"
        );
        address payable recipient;
        if (inFavourOfBuyer) {
            recipient = payable(buyer);
            state = State.JUDGED_FOR_BUYER;
        } else {
            state = State.JUDGED_FOR_SELLER;
            recipient = payable(seller);
        }
        (bool transferSuccess, ) = recipient.call{ value: value }("");
        require(transferSuccess, "transfer failed");
    }

    function buyerTimeout()
        public onlyAddress(buyer) onlyState(State.WAIT_DELIVER)
    {
        require(block.timestamp >= depositTs + duration, "too early");
        state = State.TIMED_OUT;
        (bool transferSuccess, ) = payable(buyer).call{ value: value }("");
        require(transferSuccess, "transfer failed");
    }
}
