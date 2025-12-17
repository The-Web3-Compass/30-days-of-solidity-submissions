// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./12-simpleERC20.sol";

/**
继承的SimpleERC20合约中，增加virtual
function transfer(address _to, uint256 _value) public virtual  returns (bool);
function transferFrom(address _from, address _to, uint256 _value) public virtual  returns (bool);

**/

contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice;  //每个代币的成本是多少eth，wei为单位
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;  //某人在单笔交易中可以发送多少eth的限制
    uint256 public maxPurchase;
    uint256 public totalRaised;  //目前为止已经收集了多少eth
    address public projectOwner; //出售完成后收到eth的地址
    bool public finalized = false;  //拍卖是否结束
    bool private initialTransferDone = false; //确保合约在锁定转帐前收到所有代币

    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount); //记录buyer购买了tokenAmount的代币，花费了etherAmount的eth
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    constructor(uint256 _initialSupply,
                uint256 _tokenPrice,
                uint256 _saleDurationInSeconds,
                uint256 _minPurchase,
                uint256 _maxPurchase,
                address _projectOwner) SimpleERC20(_initialSupply) {
                    tokenPrice = _tokenPrice;
                    saleStartTime = block.timestamp;
                    saleEndTime = block.timestamp + _saleDurationInSeconds;
                    minPurchase = _minPurchase;
                    maxPurchase = _maxPurchase;
                    projectOwner = _projectOwner;

                    _transfer(msg.sender, address(this), totalSupply);
                    initialTransferDone = true;

                }

    function isSaleActive() public view returns (bool) {
        return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);

    }

    //购买函数
    function buyTokens() public payable {
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below minimum purchase");
        require(msg.value <= maxPurchase, "Amount exceeds maximum purchase");
        
        uint256 tokenAmount = (msg.value * 10 ** uint256(decimals)) / tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount, "not enough tokens left for sale");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);

    }

    //覆盖方法，锁定直接传输
    function transfer(address _to, uint256 _value) public override returns (bool) {
        if(!finalized && msg.sender != address(this) && initialTransferDone) {
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);

    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if(!finalized && _from != address(this)) {
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transFrom(_from, _to, _value);

    }

    //结束代币销售
    function finalizeSale() public payable {
        require(msg.sender == projectOwner, "Only Owner can call the function");
        require(!finalized, "sale already finalized");
        require(block.timestamp > saleEndTime, "Sale not finished yet");

        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];

        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "Transfer to project owner failed");

        emit SaleFinalized(totalRaised, tokensSold);

    }

    //距离销售结束还剩多长时间
    function timeRemaining() public view returns (uint256) {
        if(block.timestamp >= saleEndTime) {
            return 0;
        }
        return saleEndTime - block.timestamp;

    }

    //仍然有多少代币可供购买
    function tokensAvailable() public view returns (uint256) {
        return balanceOf[address(this)];

    }


    //回退eth处理程序
    receive() external payable {
        buyTokens();
    }




}