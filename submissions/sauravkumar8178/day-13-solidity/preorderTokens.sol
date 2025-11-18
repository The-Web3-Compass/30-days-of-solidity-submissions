// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MyToken.sol";

contract TokenSale {
    MyToken public token;
    address public owner;
    uint256 public tokensPerEth;
    bool public saleActive;

    event TokensPurchased(address indexed buyer, uint256 ethSpent, uint256 tokensBought);
    event SaleToggled(bool newState);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event EtherWithdrawn(address indexed to, uint256 amount);
    event TokensWithdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _tokenAddress, uint256 _tokensPerEth) {
        require(_tokenAddress != address(0), "Invalid token");
        owner = msg.sender;
        token = MyToken(_tokenAddress);
        tokensPerEth = _tokensPerEth;
        saleActive = true;
    }

    function buyTokens() public payable {
        require(saleActive, "Sale not active");
        require(msg.value > 0, "Send ETH to buy tokens");

        uint256 tokensToBuy = (msg.value * tokensPerEth) / 1 ether;
        require(tokensToBuy > 0, "Not enough ETH for 1 token");

        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= tokensToBuy, "Not enough tokens in contract");

        token.transfer(msg.sender, tokensToBuy);
        emit TokensPurchased(msg.sender, msg.value, tokensToBuy);
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Price must be > 0");
        emit PriceUpdated(tokensPerEth, _newPrice);
        tokensPerEth = _newPrice;
    }

    function toggleSale(bool _state) external onlyOwner {
        saleActive = _state;
        emit SaleToggled(_state);
    }

    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No Ether");
        payable(owner).transfer(amount);
        emit EtherWithdrawn(owner, amount);
    }

    function withdrawTokens() external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens");
        token.transfer(owner, amount);
        emit TokensWithdrawn(owner, amount);
    }

    receive() external payable {
        buyTokens();
    }
}
