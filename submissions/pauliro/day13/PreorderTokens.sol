//SPDX-License-Identifier: MIT

/*
    Build a contract to sell your tokens for Ether. 
    You'll learn how to set a price and manage sales, demonstrating token economics. 
    It's like a pre-sale for your digital currency, showing how to sell tokens for Ether.
*/

pragma solidity ^0.8.0;

import "../day12/MyFirstToken.sol";

contract PreOrderToken is MyFirstToken {

    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;
    bool public finalized = false;
    bool private initialTransferDone = false;

    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    constructor( 
        address _projectOwner, uint256 _intitialSupply,
        uint256 _tokenPrice, uint256 _saleDurationInSeconds, uint256 _minPurchase, uint256 _maxPurchase ) 
    
        MyFirstToken (_intitialSupply){
            tokenPrice = _tokenPrice;
            saleStartTime = block.timestamp;
            saleEndTime = block.timestamp + _saleDurationInSeconds;
            minPurchase = _minPurchase;
            maxPurchase = _maxPurchase;
            projectOwner = _projectOwner;
            _transfer(msg.sender, address(this), totalTokens);
            initialTransferDone = true;
        }
    
        function isSaleActive()public view returns(bool){
            return(!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
        }

        function buyTokens() public payable{
            require(isSaleActive(), "Sale is not active");
            require(msg.value >= minPurchase, "Amount is below min purchase");
            require(msg.value <= maxPurchase, "Amount is above max purchase");
            uint256 tokenAmount = (msg.value * 10**uint256(decimals))/ tokenPrice;
            require(balanceOfTokens[address(this)] >= tokenAmount, "Not enough tokens left for sale");
            totalRaised+= msg.value;
            _transfer(address(this),msg.sender,tokenAmount);
            emit TokensPurchased(msg.sender, msg.value, tokenAmount);
            
        }

        function transfer(address _to, uint256 _value)public override returns(bool){
            if(!finalized && msg.sender != address(this) && initialTransferDone){
                require(false, "Tokens are locked until sale is finished");
            }
            return super.transfer(_to, _value);
        }

        function transferFrom(address _from, address _to, uint256 _value)public override returns(bool){
            if(!finalized && _from != address(this)){
                require(false, "Tokens are locked until sale is finished");
            }
            return super.transferFrom(_from, _to, _value);
        }

        function finalizeSale() public payable{
            require(msg.sender == projectOwner, "Only owner can call this function");
            require(!finalized,"Sale is already finished");
            require (block.timestamp > saleEndTime, "Sale not finished yet");
            finalized = true;
            //uint256 tokensSold = tokensAllowance - balanceOfTokens[address(this)];
            uint256 tokensSold = totalTokens - balanceOfTokens[address(this)];
            (bool sucess,) = projectOwner.call{value:  address(this).balance}("");
            require(sucess, "Transfer failed");
            emit SaleFinalized(totalRaised, tokensSold);
        }

        function timeRemaining() public view  returns(uint256){
            if(block.timestamp >= saleEndTime){
                return 0;
            }
            return (saleEndTime - block.timestamp);
        }

        function tokensAvailable()public view returns(uint256){
            return balanceOfTokens[address(this)];
        }

        receive() external payable{
            buyTokens();
        }
}