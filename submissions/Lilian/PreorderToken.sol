// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import"./SimpleERC20.sol";

contract PreorderToken is SimpleERC20{

    uint256 public tokenprice;//每个代币的价值
    uint256 public saleStartTime;
    uint256 public saleEndTime;//发售时间
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;//目前为止接受的ETH总额
    address public projectOwner;//结束的ETH地址
    bool public finalized = false;
    bool private intitalTransferDone = false;//用于确保在锁定合约前已经收到

    event TokenPurchased(address indexed buyer,uint256 etherAmount,uint256 tokenAmount);//成功购买代币时触发
    event SaleFinalized(uint256 totalRaised,uint256 totalTokenSale);//结束时触发

    constructor(
        uint256 _initalSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    )SimpleERC20(_initalSupply){
        tokenprice=_tokenPrice;
        saleStartTime=block.timestamp;
        saleEndTime=block.timestamp + _saleDurationInSeconds;
        minPurchase=_minPurchase;
        maxPurchase=_maxPurchase;
        projectOwner=_projectOwner;

        _transfer(msg.sender,address(this),totalSupply);

        intitalTransferDone=true;//做标记，标记从部署者到合约交接已完成
    }
    function isSaleActive()public view returns (bool){
        return (!finalized && block.timestamp>=saleStartTime && block.timestamp <= saleEndTime);//检查发售是否进行
    }
    function buyTokens()public payable {
        require(isSaleActive(),"Sale is not Active");//检查发售是否在进行
        require(msg.value>=minPurchase,"Amount is below minimum purchase");
        require(msg.value<=maxPurchase,"Amount exceeds maxmum purchase");//确保金额在允许范围内

        uint256 tokenAmount = (msg.value * 10**uint256(decimals))/tokenprice;//算出买家收到的代币数量
        require(balanceOf[address(this)]>=tokenAmount,"Not enough tokens left for sale");//检查是否有足够的代币

        totalRaised += msg.value;//记录累积的总额
        _transfer(address(this),msg.sender,tokenAmount);//把账户里的代币转给买家
        emit TokenPurchased(msg.sender, msg.value, tokenAmount);//触发tokenPurchased事件
    }
    function transfer (address _to,uint256 _value)public override returns (bool){
        if(!finalized && msg.sender !=address(this) && intitalTransferDone){
            require(false,"Tokens are locked until sale is finalized");//保证交易期间没人交易货币
        }
        return super.transfer(_to,_value);//发售已完成，调用原始函数
    }
    function transferFrom(address _from,address _to,uint256 _value)public override returns (bool){
        if (!finalized && _from!=address(this)){
            require(false,"Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from,_to,_value);//检查通过，用super恢复原本的转账逻辑
    }
    function finalizedSale() public payable {
        require(msg.owner == projectOwner,"Only Owner can call the function");
        require(!finalized,"Sale already finalized");//是否发售
        require(block.timestamp>saleEndTime,"Sale not finished yet");//发售是否结束

        finalized = true;//修改状态，以便系统识别
        uint256 tokensold = totalSupply - balanceOf[address(this)];//计算发售的货币

        (bool success,)=projectOwner.call{value:address(this).balance}("");
        require(success,"Transfer to project owner failed");

        emit SaleFinalized(totalRaised, tokensold);
    }
    function timeRemaining()public view returns (uint256){
        if (block.timestamp >= saleEndTime){
            return  0;
        }
        return saleEndTime -block.timestamp;
    }
    function tokensAvailable() public view returns (uint256){
        return balanceOf[address(this)];//可购买代币数量
    }
    receive() external payable {
        buyTokens();
     }


}