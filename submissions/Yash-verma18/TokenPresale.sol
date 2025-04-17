// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function balanceOf(address _owner) external  view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external  returns (bool success);
}

contract TokenPresale {
    
    address public owner;
    IERC20 public token;
    uint256 public tokenPrice;
    bool public isSaleEnd = false;
    
    event TokenBought(address indexed buyer, uint256 noOfTokensBought); 
    event ETHWithdrawn(address to, uint256 amount);
    event NewTokenPriceSet(uint256 newPrice);
    event SaleEnded(bool isEnded);
    
    
    modifier onlyOwner () {
        require(msg.sender == owner, "Only Admin Can Call this");
        _;
    }

    constructor(address _token, uint256 _price) {
        owner = msg.sender;
        token = IERC20(_token);
        tokenPrice = _price;
    }

    function buyTokens() public payable returns (bool) {
        
        require(msg.value > 0, "Send ETH to buy tokens");
        require(!isSaleEnd, "Sale is Ended");

        uint256 amountToBuy = msg.value / tokenPrice;

        require(amountToBuy > 0, "Not enough ETH sent for even 1 token");
        require(amountToBuy <= token.balanceOf(address(this)), "Not enough tokens in contract");

        token.transfer(msg.sender, amountToBuy);

        emit TokenBought(msg.sender, amountToBuy);
        return true;
    }
    
    function withdrawETH() onlyOwner public {
        uint256 contractBalance = address(this).balance;
        (bool success, ) = payable(owner).call{value : contractBalance}("");
        require(success, "Transaction failed");
        emit ETHWithdrawn(owner, contractBalance);
    }
    
    function setTokenPrice(uint256 newPrice) onlyOwner public{
        require(newPrice > 0, "Invalid New Price");
        require(newPrice !=  tokenPrice, "Token price already set");
        tokenPrice = newPrice;
        emit NewTokenPriceSet(newPrice);
    }

    function endSale() onlyOwner public {
        require(!isSaleEnd, "Sale Already ended");
        
        uint256 remainingTokens = token.balanceOf(address(this));
        
        // sending remainingTokens to owner address
        token.transfer(owner, remainingTokens);
        
        
        isSaleEnd = true;
        emit SaleEnded(true);
    }

    function numberOfTokensInContract() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    
}