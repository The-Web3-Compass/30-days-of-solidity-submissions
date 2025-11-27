//ICO！！代币函数标记为可重写
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20^;

function transfer(address _to, uint256 _value) public virtual returns (bool);
function transferForm(address _from, address _to, uint256 _value) public virtual returns (bool);

contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice;//每个代币值多少 ETH（单位是 wei，1 ETH = 10¹⁸ wei）
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;
    bool public finalized = false;
    bool private initialTransferDone = false;
}

event TokenPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
event SaleFinalized(uint256 totalRaised, uint256 to talTokensSold);

constructor(
    uint256 _initialSupply,
    uint256 _tokenPrice,
    uint256 _saleDurationInSeconds,
    uint256 _minPurchase,
    uint256 _maxPurchase,
    address _projectOwner
) SimpleERC20(_initialSupply){//构造函数，
    tokenPrice = _tokenPrice;
    saleStartTime = block.timestamp;
    saleStartTime = block.timestamp + _saleDurationInSeconds;
    minPurchase = _minPurchase;
    maxPurchase = _maxPurchase;
    projectOwner = _projectOwner;

    //将所有代币转移至此合约用于发售
    _transfer(msg.sender, address(this), totalSupply);
    initialTransferDone = true;//标记我们已经从部署者那里转移了代币
}

function isSaleActive() public view returns (bool)
{
    return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndtime);
}

function buyTokens() public payable {//检查发售是否还在进行
    require(isSaleActive(), "Sale is not active");
    require(msg.sender >= minPurchase, "Amount is be low minium purchase");
    require(msg.value <= maxPurchase, "Amount exceeds maximun purchase");
    uint256 tokenAmount = (msg.value * 10** uint256 (decimals)) / tokenPrice;
    require(balanceOf[addres(this)])>= tokenAmount, "Not enough tokens left for sale";
    totalRaised += msg.value;//确保合约里有足够的代币
    _transfer(address(this), msg.sender, tokenAmount);//把代币转给买家
    emit TokensPurchased(msg.sender, msg.value, tokenAmount);
}

function transfer(address, _to, uint256 _value) public override returns (bool){//检查发售
    if (!finalized && msg.sender != address(this) && initialTransferDone){
        require(false, "Tokens are locked until sale is finalized");
    }
    return super.transfer(_to, _value);//正常转账
}

function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    if (!finalized && _from != address(this)) {//发售锁定检查
        require(false, "Tokens are locked until sale is finalized");//恢复默认逻辑
    }
    return super.transferFrom(_from, _to, _value);
}

function finalizeSale() public payable{//- 筹集的 ETH总额\售出的代币数量
    require(msg.sender == projectOwner, "Only Owner can call the function");//访问控制和计时
    require(!finalized, "Sale already finalized");
    require(block.timestamp > saleEndTime, "Sale not finished yet");//确保发售期已结束（依据结束时间戳）——从而不能提前终止发售。
    finalize = true;
    uint256 tokensSold = totalSupply - balanceOf[address(this)];//计算已售出的代币数量
    (bool success, ) = projectOwner.call{value: address(this).balance}("");
    require(success, "Transfer to project owner falied");
    emit SaleFinalized(totalRaised, tokensSold);
}


//这两个只读函数为前端、看板或其他智能合约提供便捷的实时信息查询能力。
function timeRemaining() public view returns (uint256) {
    if (block.timestamp >= saleEndTime) {
        return 0;
    }
    requre saleEndTime = block.timestamp
}

function tokensAvailable() public view returns (uint256) {
    return balanceOf[address(this)];
}
// 前端或 DApp 可显示"剩余 X 个代币"，让买家及时了解库存、提升决策效率


receive() external payable {
    butTokens();
}
//在 Solidity 中，`receive()` 函数是一个**特殊的回退函数**，在满足以下条件时被触发：
//- 有人**直接**向合约地址发送 ETH
//- 且**未指定**要调用的任何函数