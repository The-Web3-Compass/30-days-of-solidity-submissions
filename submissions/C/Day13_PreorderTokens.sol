// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "Day12_MyFirstToken.sol";

contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice; // 每个代币的价格是多少ETH
    uint256 public saleStartTime; // 销售开始时间
    uint256 public saleEndTime; // 销售结束时间
    uint256 public minPurchase; // 最小可以发送ETH数量
    uint256 public maxPurchase; // 最大可以发送ETH数量
    uint256 public totalRaised; // 目前已筹集ETH总数
    address public projectOwner; // 项目完成后接收ETH的地址
    bool public finalized = false; // 销售是否已结束
    bool public initialTransferDone = false; // 确保合约锁定转账前接收所有代币

    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount); // 购买时触发 购买地址 支付ETH数量 收到代币数量
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold); // 销售结束时触发 总的ETH数量 及 售出代币数量

    constructor(
        uint256 _initialSupply, // 代币初始供给量
        uint256 _tokenPrice, // 代币价格
        uint256 _saleDurationInSeconds, //
        uint256 _minPurchase, // 最小购买 wei单位
        uint256 _maxPurchase, // 最多购买 wei单位
        address _projectOwner // 项目创建者的地址 最终收款地址
    ) SimpleERC20(_initialSupply) {
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp; // 现在的部署时间就是活动开始的时间
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        _transfer(msg.sender, address(this), totalSupply);

        initialTransferDone = true; // 由合约做代币分发
    }

    // 代币售卖是否已结束
    function isSaleActive() public view returns(bool) {
        return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    // 购买
    function buyTokens() public payable{
        require(isSaleActive(), "Sale is not active"); // 是否在可售卖时间内
        require(msg.value >= minPurchase, "Amount is below minimum purchase"); // 最小限制
        require(msg.value <= maxPurchase, "Amount exceeds maximun purchase"); // 最大限制
        uint256 tokenAmount = (msg.value * 10 ** uint256(decimals)) /tokenPrice; // 计算需要发送多少代币

        require(balanceOf[address(this)]>= tokenAmount, "Not enough tokens left for sale"); // 确认合约是否有足够代币

        totalRaised += msg.value; // 记录ETH总额
        _transfer(address(this), msg.sender, tokenAmount); // 代币转移给买家
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }
    
    // 覆盖transfer
    function transfer(address _to, uint256 _value) public override returns (bool){
        // 售卖未完成  交易非合约发起 初始代币已转移至合约
        if(!finalized && msg.sender != address(this) && initialTransferDone){
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);
    }

    // 覆盖transferFrom
    function transferFrom(address _from, address _to, uint256 _value)public override returns(bool){
        if(!finalized && _from != address(this)){
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    // 结束代币售卖
    function finalizeSale() public payable{
        require(msg.sender == projectOwner, "Only Owner can call the function");
        require(!finalized, "Sale already finalized");
        require(block.timestamp > saleEndTime, "Sale not finished yet");

        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];

        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "Transfer to project owner failed");

        emit SaleFinalized(totalRaised, tokensSold);
    }

    // 显示倒计时
    function timeRemaining() public view returns (uint256){
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return saleEndTime - block.timestamp;
    }
    
    // 显示余下代币可购买
    function tokensAvailable() public view returns (uint256){
        return balanceOf[address(this)];
    }

    // 备用ETH处理器
    receive() external payable{
        buyTokens();
    }
}