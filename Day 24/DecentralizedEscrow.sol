// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DecentralizedEscrow - A simple conditional payment contract
/// @author ...
/// @notice Holds funds until buyer confirms delivery or dispute is resolved

contract DecentralizedEscrow {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    bool public isFunded;
    bool public isReleased;
    bool public isRefunded;

    event Funded(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer allowed");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter allowed");
        _;
    }

    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
    }

    /// @notice Buyer deposits ETH into escrow
    function fund() external payable onlyBuyer {
        require(!isFunded, "Already funded");
        require(msg.value > 0, "Send ETH to fund");
        amount = msg.value;
        isFunded = true;
        emit Funded(msg.sender, msg.value);
    }

    /// @notice Release funds to seller
    function release() external {
        require(isFunded, "Not funded");
        require(!isReleased && !isRefunded, "Already processed");
        require(msg.sender == buyer || msg.sender == arbiter, "Not authorized");

        isReleased = true;
        payable(seller).transfer(amount);
        emit Released(seller, amount);
    }

    /// @notice Refund buyer
    function refund() external {
        require(isFunded, "Not funded");
        require(!isReleased && !isRefunded, "Already processed");
        require(msg.sender == seller || msg.sender == arbiter, "Not authorized");

        isRefunded = true;
        payable(buyer).transfer(amount);
        emit Refunded(buyer, amount);
    }
}
