// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day12.sol";

contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice;     // 代币价格（msg.value的单位为wei,即使输入的单位erieth）
    uint256 public saleStartTime;  // 发售开始时间
    uint256 public saleEndTime;    // 发售结束时间
    uint256 public minPurchase;    // 最小购买ETH额度(输入值的单位为wei)
    uint256 public maxPurchase;    // 最大购买ETH额度(输入值的单位为wei)
    uint256 public totalRaised;    // 总募资ETH金额
    address public projectOwner;   // 项目属主, 发售结束后接收ETH的钱包地址
    bool public finalized = false; // 发售是否已关闭
    bool private initialTransferDone = false; // 合约初始化结束标志, 用于确保合约在锁定转账功能前已接收到所有代币

    // 代币购买事件 及 发售结束事件
    event TokenPurchase(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    // 构造函数
    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) SimpleERC20(_initialSupply){
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        // 将所有代币转移至此合约用于发售
        _transfer(msg.sender, address(this), totalSupply);
        // 标记初始化结束
        initialTransferDone = true;
    }

    // 查询发售是否正在进行
    function isSaleActive() public view returns (bool) {
        return !finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime;
    }

    // 购买函数
    function buyTokens() public payable {
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below minimum purchase");
        require(msg.value <= maxPurchase, "Amount is above maximum purchase");
        // require(msg.value >= minPurchase && msg.value <= maxPurchase, "Invalid ETH amount");
        uint256 tokenAmount = msg.value * 10 ** uint256(decimals) / tokenPrice;

        require(balanceOf[address(this)] >= tokenAmount, "Insufficient tokens left for sale");
        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokenPurchase(msg.sender, msg.value, tokenAmount);
    }

    // 重写transfer, 在发售期间锁定直接转账
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(initialTransferDone && !finalized && msg.sender != address(this), "Tokens are locked during sale");
        return super.transfer(_to, _value);
    }

    // 重写transferFrom, 发售期间锁定委托转账
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(!finalized && _from != address(this), "Tokens are locked during sale");
        return super.transferFrom(_from, _to, _value);
    }

    // 结束发售
    function finalizeSale() public payable {
        require(msg.sender == projectOwner, "Only owner can call the function");
        require(!finalized, "Sale already finalized");
        require(block.timestamp > saleEndTime, "Sale not finished yet");

        finalized = true;
        uint256 tokenSold = totalSupply - balanceOf[address(this)];
        // 将所有ETH转给项目属主
        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "Transfer to project owner failed");
        
        emit SaleFinalized(totalRaised, tokenSold);
    }

    // 查询发售剩余时间
    function timeRemaining() public view returns (uint256) {
        if (block.timestamp >= saleEndTime) {
            return 0;
        }
        return saleEndTime - block.timestamp;
    }

    // 可售代币数量
    function tokensAvailable() public view returns (uint256) {
        return balanceOf[address(this)];
    }

    // 回退处理器
    receive() external payable {
        require(isSaleActive(), "Sale is not active");
        buyTokens();
    }
}