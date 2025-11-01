// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import"./Day12-ERC20.sol";

contract SimplifiedTokenSales is SimpleERC20{

uint256 public tokenPrice;//每个代币值多少 ETH（单位是 wei，1 ETH = 10¹⁸ wei）
uint256 public saleStartTime;//表示发售开始
uint256 public saleEndTime;//结束时间的时间戳
uint256 public minPurchase;//单笔交易中允许购买的最小ETH额度
uint256 public maxPurchase;//单笔交易中允许购买的最大ETH额度
uint256 public totalRaised;//目前为止接收的 ETH总额
address public projectOwner;//发售结束后接收 ETH 的钱包地址
bool public finalized = false;//发售是否已经正式关闭
bool private initialTransferDone = false;//用于确保合约在锁定转账前已收到所有代币

event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);//当有人成功购买代币时触发。它会记录购买者、支付的 ETH 数量以及收到的代币数量。
event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);//发售结束时触发。记录筹集的 ETH 总数和售出的代币数量

constructor(
    
    uint256 _tokenPrice,
    uint256 _saleDurationInSeconds,
    uint256 _minPurchase,
    uint256 _maxPurchase,
    address _projectOwner,

    uint256 _initialSupply,
    string memory _name,
    string memory _symbol,
    uint8 _decimals) 
    
    SimpleERC20(_name,_symbol,_decimals,_initialSupply) {
    
    tokenPrice = _tokenPrice;
    saleStartTime = block.timestamp;
    saleEndTime = block.timestamp + _saleDurationInSeconds;
    minPurchase = _minPurchase;
    maxPurchase = _maxPurchase;
    projectOwner = _projectOwner;

    // 将所有代币转移至此合约用于发售
    _transfer(msg.sender, address(this), totalSupply);

    // 标记我们已经从部署者那里转移了代币
    initialTransferDone = true;
}

function isSaleActive() public view returns (bool) {//函数是用来检查发售是否正在进行
    return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
}

function buyTokens() public payable {// 主要购买函数
    require(isSaleActive(), "Sale is not active");
    require(msg.value >= minPurchase, "Amount is below minimum purchase");
    require(msg.value <= maxPurchase, "Amount exceeds maximum purchase");

    uint256 tokenAmount = (msg.value * 10**uint256(decimals)) / tokenPrice;
    require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");

    totalRaised += msg.value;
    _transfer(address(this), msg.sender, tokenAmount);
    emit TokensPurchased(msg.sender, msg.value, tokenAmount);
}
function transfer(address _to, uint256 _value) public override returns (bool) {
    if (!finalized && msg.sender != address(this) && initialTransferDone) {///检查发售是否继续，转账是否来自合约
        require(false, "Tokens are locked until sale is finalized");//如果是，交易停止
    }
    return super.transfer(_to, _value);
}



function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    if (!finalized && _from != address(this)) {//检查发售是否继续，转账是否来自合约
        require(false, "Tokens are locked until sale is finalized");//如果是，交易停止
    }
    return super.transferFrom(_from, _to, _value);// super 回退到原始的 ERC-20 transferFrom() ，恢复默认的转账逻辑

}

function finalizeSale() public payable {
    require(msg.sender == projectOwner, "Only Owner can call the function");//只有项目所有者可以调用此函数
    require(!finalized, "Sale already finalized");//检查是否已完成发售
    require(block.timestamp > saleEndTime, "Sale not finished yet");//确保发售期已结束（依据结束时间戳）

    finalized = true;//将发售标记为完成
    uint256 tokensSold = totalSupply - balanceOf[address(this)];//计算本次实际售出的代币

    (bool success, ) = projectOwner.call{value: address(this).balance}("");//向项目所有者发送 ETH
    require(success, "Transfer to project owner failed");//确保这次发送没有静默失

    emit SaleFinalized(totalRaised, tokensSold);//触发事件，筹集的ETH总额，售出代币数量
}

function timeRemaining() public view returns (uint256) {//剩余时间
    if (block.timestamp >= saleEndTime) {
        return 0;
    }
    return saleEndTime - block.timestamp;
}

function tokensAvailable() public view returns (uint256) {//剩余可购买数量
    return balanceOf[address(this)];
}

receive() external payable {//它的功能是允许ETH流入，并将 ETH 直接路由到代币销售逻辑中
    buyTokens();
}






}
