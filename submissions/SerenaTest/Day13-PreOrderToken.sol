//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "./Day12-MyToken.sol";

contract PreOrderToken is MyToken {

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
        //参数
        uint256 _intitialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    )MyToken(_intitialSupply){
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        //将所有代币转移到合约里
        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;
    }

    function isSaleActive()public view returns(bool){
        return(!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    //购买
    function buyTokens() public payable{
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below min purchase");
        require(msg.value <= maxPurchase, "Amount is above max purchase");
        //买家应获得的代币
        uint256 tokenAmount = (msg.value * 10 ** uint256(decimals)) / tokenPrice;
        //合约里要有足够的代币来满足请求
        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");
        totalRaised += msg.value;
        _transfer(address(this),msg.sender,tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
        
    }

    //重写transfer()函数（发售期间不允许转账）
    function transfer(address _to, uint256 _value)public override returns(bool){
        if(!finalized && msg.sender != address(this) && initialTransferDone){
            require(false, "Tokens are locked until sale is finalized");
        }

        //直接调用父合约的transfer()函数
        return super.transfer(_to, _value);
    }

     //重写transferFrom()函数（发售期间不允许委托转账）
    function transferFrom(address _from, address _to, uint256 _value)public override returns(bool){
        if(!finalized && _from != address(this)){
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    //结束
    function finalizeSale() public payable{
        require(msg.sender == projectOwner, "Only owner can call this function");
        require(!finalized,"Sale is already finalized");
        require (block.timestamp > saleEndTime, "Sale not finished yet");
        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];
        (bool sucess,) = projectOwner.call{value:  address(this).balance}("");
        require(sucess, "Transfer failed");
        emit SaleFinalized(totalRaised, tokensSold);
    }

    //剩余发售时间
    function timeRemaining() public view  returns(uint256){
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return (saleEndTime - block.timestamp);
    }

    //当前可购买代币数量
    function tokensAvailable()public view returns(uint256){
        return balanceOf[address(this)];
    }

    //ETH回退处理器（若有人直接向合约发送ETH没有指定调用什么函数时触发）
    receive() external payable{
        buyTokens();
    }




}