// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MyToken.sol";

// Contract that enables token pre-orders with purchase limits and sale window
contract PreOrderToken is MyToken {

    uint256 public tokenPrice;         // Price per token (in wei)
    uint256 public saleStartTime;      // Timestamp for when the sale starts
    uint256 public saleEndTime;        // Timestamp for when the sale ends
    uint256 public minPurchase;        // Minimum ETH allowed for a single purchase
    uint256 public maxPurchase;        // Maximum ETH allowed for a single purchase
    uint256 public totalRaised;        // Total amount of ETH raised from token sales
    address public projectOwner;       // Address of the project owner
    bool public finalized = false;     // Flag to indicate whether the sale has been finalized
    bool private initialTransferDone = false; // Tracks whether tokens have been transferred to contract

    // Events
    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    // Constructor sets up the token and pre-order configuration
    constructor( 
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) MyToken(_initialSupply) {
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        // Transfer all tokens to the contract itself for selling
        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;
    }

    // Returns true if sale is active and not finalized
    function isSaleActive() public view returns (bool) {
        return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    // Function to buy tokens during the sale
    function buyTokens() public payable {
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below min purchase");
        require(msg.value <= maxPurchase, "Amount is above max purchase");

        // Calculate token amount based on ETH sent and token price
        uint256 tokenAmount = (msg.value * 10**uint256(decimals)) / tokenPrice;

        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");

        totalRaised += msg.value;

        // Transfer tokens to the buyer
        _transfer(address(this), msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // Override transfer to lock tokens before sale is finalized
    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);
    }

    // Override transferFrom to lock tokens before sale is finalized
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if (!finalized && _from != address(this)) {
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    // Finalizes the token sale and transfers ETH to project owner
    function finalizeSale() public payable {
        require(msg.sender == projectOwner, "Only owner can call this function");
        require(!finalized, "Sale is already finalized");
        require(block.timestamp > saleEndTime, "Sale not finished yet");

        finalized = true;

        // Calculate how many tokens were sold
        uint256 tokensSold = totalSupply - balanceOf[address(this)];

        // Transfer raised funds to project owner
        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "Transfer failed");

        emit SaleFinalized(totalRaised, tokensSold);
    }

    // View function to get time remaining in the sale
    function timeRemaining() public view returns (uint256) {
        if (block.timestamp >= saleEndTime) {
            return 0;
        }
        return saleEndTime - block.timestamp;
    }

    // View function to get number of tokens still available for purchase
    function tokensAvailable() public view returns (uint256) {
        return balanceOf[address(this)];
    }

    // Fallback function: automatically called when contract receives ETH
    receive() external payable {
        buyTokens();
    }
}