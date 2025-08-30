// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyFirstToken.sol";

contract PreorderTokens is MyFirstToken {
    uint256 public tokenPrice; // Price in wei (1 ETH = 10^18 wei)
    bool public saleActive;
    address public owner;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;
    bool public finalized = false;
    bool private initialTransferDone = false;

    event TokensPurchased(address buyer, uint256 amount, uint256 cost);
    event SaleStatusChanged(bool isActive);
    event TokenPriceUpdated(uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) MyFirstToken(_initialSupply) {
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        // Transfer all tokens to this contract for sale
        _transfer(msg.sender, address(this), totalSupply);

        // Mark that we've moved tokens from the deployer
        initialTransferDone = true;
    }

    function purchaseTokens() external payable {
        require(saleActive, "Token sale is not active");
        require(msg.value > 0, "Must send ETH to purchase tokens");

        uint256 tokenAmount = (msg.value * 10 ** decimals) / tokenPrice;
        require(
            tokenAmount > 0,
            "Amount of tokens to purchase must be greater than 0"
        );

        _mint(msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than 0");
        tokenPrice = newPrice;
        emit TokenPriceUpdated(newPrice);
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
        emit SaleStatusChanged(saleActive);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "ETH withdrawal failed");
    }

    // Function to receive ETH
    receive() external payable {}
}
