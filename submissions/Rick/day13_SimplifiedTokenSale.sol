// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day12_SimpleERC20.sol";

contract SimplifiedTokenSale is SimpleERC20 {
    // 1个ETH 值多少个代币
    uint256 public tokenPrice;
    // 销售期开始时间
    uint256 public saleStartTime;
    // 销售期结束时间
    uint256 public saleEndTime;
    // 每次购买最小数量
    uint256 public minPurchase;
    // 每次购买最大数量
    uint256 public maxPurchase;
    // 销售一共得到ETH数量
    uint256 public totalRaised;
    // 代币拥有者
    address public projectOwner;
    // 销售期结束转态
    bool public finalized = false;
    // 代币是否初始化，转移到合约账户中
    bool private initialTransferDone = false;

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) SimpleERC20(_initialSupply) {
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

    // 谁 花了多少个ETH 买了多少个代币
    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    // 销售期结束后 供得到多少个ETH  卖出去多少个代币
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);


    /*
        查询当前是否处于销售期
    
        block.timestamp 是 Solidity 中唯一的“时间来源”，
        代表当前区块打包时的时间，
        也是区块链世界中最接近实时的时间戳。
    */
    function isSaleActive() public view returns(bool){
        return initialTransferDone && block.timestamp >= saleStartTime  && block.timestamp <= saleEndTime;
    }

    function buyToken()public payable{
        require(isSaleActive(),unicode"不是销售期");
        require(msg.value >= minPurchase ,unicode"购买数量不符合要求");
        require(msg.value <= maxPurchase ,unicode"购买数量不符合要求");


        // 根据tokenPrice 计算本次请求的ETH数量等同多少个代币
        uint tokenAmount =( msg.value * 10 ** decimals) / tokenPrice;
        _transfer(address(this),msg.sender,tokenAmount);
        totalRaised += msg.value;

        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // 重写transfer方法
    function transfer(address _to,uint _value) public override  returns (bool){
        if(initialTransferDone && !finalized && msg.sender != address(this)){
            require(false , unicode"违规转账");
        }
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from , address _to , uint _value) public override  returns (bool){
        if(initialTransferDone && !finalized && _from != address(this)){
            require(false , unicode"违规转账");
        }
        return super.transferFrom(_from,_to,_value);
    }
    // 销售期结束后进行结算，将合约账户的ETH转到个人钱包
    function finalizeSale() public payable {
        require(msg.sender == projectOwner,unicode"只允许合约拥有者进行结算");
        require(block.timestamp >= saleEndTime , unicode"销售期未结束");
        require(!finalized,unicode"不允许重复结算");

        finalized = true;
        uint totalAmount = totalSupply - balanceOf[address(this)];

        (bool success ,) = projectOwner.call{value : address(this).balance}("");
        require(success , unicode"结算转账失败");

        emit SaleFinalized(address(this).balance, totalAmount);
    }

    // 查询销售期结束剩余多少时间
    function timeRemaining() public view returns(uint) {
        require(block.timestamp >= saleStartTime ,unicode"销售期未开始");
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return block.timestamp - saleEndTime;
    }

    // 查询一共剩余多少代币待销售
    function tokensAvailable() public view returns (uint){
        return balanceOf[address(this)];
    }

    /*
        
    */
    receive() external payable { 
        buyToken();
    }
}
