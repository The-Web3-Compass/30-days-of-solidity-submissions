// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedEscrow {

    address public buyer;
    address public seller;
    address public arbiter;

    uint256 public amount;
    bool public isFunded;
    bool public isReleased;
    bool public isDisputed;

    event Funded(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);
    event Disputed();
    event Resolved(address winner);

    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter");
        _;
    }

    /*
     * Buyer deposits funds
     */
    function deposit() external payable onlyBuyer {
        require(!isFunded, "Already funded");
        require(msg.value > 0, "Send ETH");

        amount = msg.value;
        isFunded = true;

        emit Funded(msg.sender, msg.value);
    }

    /*
     * Buyer releases payment to seller
     */
    function releasePayment() external onlyBuyer {
        require(isFunded, "Not funded");
        require(!isReleased, "Already released");
        require(!isDisputed, "Under dispute");

        isReleased = true;

        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Transfer failed");

        emit Released(seller, amount);
    }

    /*
     * Raise dispute
     */
    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not allowed");
        require(isFunded, "Not funded");
        require(!isReleased, "Already completed");

        isDisputed = true;

        emit Disputed();
    }

    /*
     * Arbiter resolves dispute
     */
    function resolveDispute(bool releaseToSeller) external onlyArbiter {
        require(isDisputed, "No dispute");

        isReleased = true;

        if (releaseToSeller) {
            (bool success, ) = payable(seller).call{value: amount}("");
            require(success, "Transfer failed");
            emit Resolved(seller);
        } else {
            (bool success, ) = payable(buyer).call{value: amount}("");
            require(success, "Transfer failed");
            emit Resolved(buyer);
        }
    }

    /*
     * Refund buyer (if seller agrees or no dispute)
     */
    function refundBuyer() external onlySeller {
        require(isFunded, "Not funded");
        require(!isReleased, "Already released");
        require(!isDisputed, "Under dispute");

        isReleased = true;

        (bool success, ) = payable(buyer).call{value: amount}("");
        require(success, "Transfer failed");

        emit Refunded(buyer, amount);
    }
}