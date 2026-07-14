// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SimpleERC20.sol";

contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice;  // Price per token in wei (smallest unit of ETH)
    uint256 public saleStartTime;  // Timestamp when the sale starts
    uint256 public saleEndTime;  // Timestamp when the sale ends
    uint256 public minPurchase;  // Minimum purchase amount (in wei)
    uint256 public maxPurchase;  // Maximum purchase amount (in wei)
    uint256 public totalRaised;  // Total ETH raised
    address public projectOwner;  // Project owner's address
    bool public finalized = false;  // Sale finalized flag

    bool private initialTransferDone = false;  // To prevent premature transfers

    // Events
    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    // Constructor
    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) SimpleERC20(_initialSupply) {
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        // Transfer all tokens to the sale contract
        _transfer(msg.sender, address(this), totalSupply);

        // Mark initial transfer as done
        initialTransferDone = true;
    }

    // Modifier to check if the sale is active
    modifier isSaleActive() {
        require(block.timestamp >= saleStartTime && block.timestamp <= saleEndTime, "Sale is not active");
        _;
    }

    // Function to buy tokens during the sale
    function buyTokens() external payable isSaleActive {
        uint256 etherAmount = msg.value;
        require(etherAmount >= minPurchase, "Below minimum purchase amount");
        require(etherAmount <= maxPurchase, "Above maximum purchase amount");

        // Calculate the amount of tokens to be purchased
        uint256 tokenAmount = etherAmount / tokenPrice;

        // Ensure the contract has enough tokens to sell
        require(balanceOf(address(this)) >= tokenAmount, "Not enough tokens in the sale contract");

        // Transfer tokens to the buyer
        _transfer(address(this), msg.sender, tokenAmount);

        // Update total raised funds
        totalRaised += etherAmount;

        // Emit purchase event
        emit TokensPurchased(msg.sender, etherAmount, tokenAmount);
    }

    // Function to finalize the sale (can only be done by the project owner)
    function finalizeSale() external {
        require(msg.sender == projectOwner, "Only the project owner can finalize the sale");
        require(!finalized, "Sale is already finalized");
        require(block.timestamp > saleEndTime, "Sale has not ended yet");

        // Transfer the raised ETH to the project owner
        payable(projectOwner).transfer(totalRaised);

        // Mark the sale as finalized
        finalized = true;

        // Emit sale finalized event
        emit SaleFinalized(totalRaised, balanceOf(address(this)));
    }

    // Overr
