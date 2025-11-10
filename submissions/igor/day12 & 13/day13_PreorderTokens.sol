// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day12/day12_simpleERC20.sol";

contract PreorderTokens is simpleERC20{
    uint256 public tokenPrice;
    uint256 saleStartTime;
    uint256 saleEndTime;
    uint256 minPurchase;
    uint256 maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;      // who can finalize and withdraw
    bool public finalized = false;
    bool private initialTransferDone = false;

    //event
    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    constructor(uint256 _initialSupply,
                uint256 _tokenPrice,
                uint256 _saleDurationInSeconds,
                uint256 _minPurchase,
                uint256 _maxPurchase,
                address _projectOwner) simpleERC20(_initialSupply){
        require(_projectOwner != address(0), "Invalid project owner");
        require(_tokenPrice > 0, "Token price must be > 0");
        require(_saleDurationInSeconds > 0, "Duration must be > 0");
        require(_maxPurchase >= _minPurchase, "maxPurchase must >= minPurchase");

        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        // 将部署者持有的全部代币转移到合约地址以供售卖
        // NOTE: msg.sender 仍为部署者，这里父合约已把代币铸给了 msg.sender
        _transfer(msg.sender, address(this), totalSupply);

        initialTransferDone = true;
    }
    
    function isSaleActive()public view returns(bool){
        return(!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    function buyTokens() public payable{
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase,"send more");
        require(msg.value <= maxPurchase,"send less");

        uint256 tokenAmount = msg.value * 10**uint256(decimals) / tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount,"not enough tokens");
        require(tokenAmount > 0,"send more");
        totalRaised += msg.value;

        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);

    }

    function transfer(address _to,uint256 _value)public override returns(bool){
        require(!finalized && msg.sender != address(this) && initialTransferDone,"Tokens are locked until sale is finalized");
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from,address _to,uint256 _value) public override returns(bool){
        require(!finalized && _from != address(this) && initialTransferDone,"Tokens are locked until sale is finalized");
        return super.transferFrom(_from,_to,_value);
    }

    //end the presale and start the distribution
    function finalizeSale() public{
        require(msg.sender == projectOwner,"only Owner can do");
        require(!finalized,"Sale already done");
        require(block.timestamp > saleEndTime,"Sale not finished");

        finalized = true;
        uint256 tokenSold = totalSupply - balanceOf[address(this)];

        uint256 balance = address(this).balance;
        (bool success,) = msg.sender.call{value: balance}("");
        require(success,"Tx failed!");
        emit SaleFinalized(tokenSold,balance);
    }

    function timeRemaining() public view returns(uint256){
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return saleEndTime - saleStartTime;
    }

    function tokensAvailable() public view returns(uint256){
        return balanceOf[address(this)];
    }

}