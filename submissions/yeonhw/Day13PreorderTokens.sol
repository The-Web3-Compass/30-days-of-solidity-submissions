// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import './Day12MyFirstTokenContract.sol';

contract SimplifiedTokenSale is SimpleERC20{
    uint256 public tokenPrice;  //每个代币需要多少ETH（wei）
    uint256 public saleStartTime;  //销售的开始时间
    uint256 public saleEndTime;  //销售的结束时间
    uint256 public minPurchase;
    uint256 public maxPurchase;  //单笔交易中可以发送的ETH金额限制
    uint256 public totalRaised;  //目前为止收到的ETH数量
    address public projectOwner;  //销售完成后接受ETH的地址
    bool public finalized = false;  //确认销售是否结束
    bool private initialTransferDone = false;  //用于确保合约在锁定转账之前收到所有tokens

    event TokensPurchased(address indexed buyer, uint256 etherAmout, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInseconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) SimpleERC20(_initialSupply){
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInseconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        //将所有的token转移到这个contract上来销售
        _transfer(msg.sender, address(this), totalSupply);

        //标记我们已经从deployer转移了token
        initialTransferDone = true;
    }

    function isSaleActive() public view returns (bool) {
        return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    function buyTokens() public payable{
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below minimum purchase");
        require(msg.value <= maxPurchase, "Amount exceeds maximum purchase");

        uint256 tokenAmount = (msg.value * 10 ** uint256(decimals)) / tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    //在销售进行时暂时限制token的转移
    function transfer(address _to, uint256 _value) public override returns (bool){
        if(!finalized && msg.sender != address(this) && initialTransferDone){
        //销售尚未完成 && 交易不是由合约本身发起的  && 初始token以转入合约 =》确保没有人可以在销售期间将token发送给他人或进行交易
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
        // 销售锁定检查
        if (!finalized && _from != address(this)){
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value); //回退到默认逻辑
    }

    //结束token销售
    function finalizedSale() public payable {
        require(msg.sender == projectOwner, "Only owner can call the function");
        require(!finalized, "Sale already finalized");
        require(block.timestamp > saleEndTime, "Sale not finished yet");

        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];

        (bool success, ) = projectOwner.call{value: address(this).balance}("");  //将合约中销售得到的ETH转给所有者
        require(success, "Transfer to project owner failed");

        emit SaleFinalized(totalRaised, tokensSold);
    }

    function timeRemaining() public view  returns(uint256){
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return (saleEndTime - block.timestamp);
    }

    function tokensAvailable()public view returns(uint256){
        return balanceOf[address(this)];
    }

    receive() external payable{
        buyTokens();
    }
}
