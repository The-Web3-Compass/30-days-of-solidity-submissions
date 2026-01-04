// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "submissions/SylvaQing/day12/day12-SimpleERC20.sol";

contract SimplifiedTokenSale is SimpleERC20 {
    // 状态变量
    uint256 public tokenPrice; //每个代币值多少 ETH
    uint256 public saleStartTime; //发售开始和结束时间
    uint256 public saleEndTime; 
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;
    bool public finalized = false;
    bool private initialTransferDone = false; //确保合约在锁定转账前已收到所有代币

    // 事件
    // 购买成功
    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    //发售结束
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    //构造函数！没有这个会报错
    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) SimpleERC20(_initialSupply) {
        //母类没有的内容
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        // 将所有代币转移至此合约用于发售
        _transfer(msg.sender, address(this), totalSupply);

        // 标记我们已经从部署者那里转移了代币, transfer() 函数中使用
        initialTransferDone = true;
    }

    //检查发售是否正在进行
    function isSaleActive() public view returns (bool){
        return (!finalized&& block.timestamp>=saleStartTime&&block.timestamp<=saleEndTime);
    }
    // 购买函数
    function buyTokens() public payable{
        require(isSaleActive(),"Sale is not active");
        require(msg.value>=minPurchase&&msg.value<=maxPurchase,"Invalid ETH amount");
        // uint256 tokenAmount = msg.value/tokenPrice;
        uint256 tokenAmount = (msg.value*10**uint256(decimals))/tokenPrice;
        require(tokenAmount>0,"ETH amount too low");
        _transfer(address(this),msg.sender,tokenAmount);
        totalRaised += msg.value;
        emit TokensPurchased(msg.sender,msg.value,tokenAmount);
    }
    // 重写 transfer() — 锁定直接转账
    function transfer(address _to,uint256 _value)public override returns (bool){
        require(initialTransferDone,"Initial transfer not done yet");
        require(!finalized,"Sale is finalized");
        return super.transfer(_to,_value);
    }
    // 重写 transferFrom() — 锁定委托转账
    function transferFrom(address _from,address _to,uint256 _value)public override returns (bool){
        require(initialTransferDone,"Initial transfer not done yet");
        require(!finalized,"Sale is finalized");
        return super.transferFrom(_from,_to,_value);
    }
    // 结束发售
    function finalizeSale()public payable {
        //访问控制和计时
        require(msg.sender==projectOwner,"Only project owner can finalize sale");
        require(!finalized,"Sale is already finalized");
        require(block.timestamp>=saleEndTime,"Sale is still active");
        finalized = true;
        
        uint256 tokensSold=totalSupply-balanceOf[address(this)]; //计算已售出的代币数量
        // 向项目所有者发送 ETH
        (bool success,)=projectOwner.call{value:address(this).balance}("");
        require(success,"Failed to send ETH to project owner");

        // emit SaleFinalized(totalRaised,totalSupply);
        emit SaleFinalized(totalRaised, tokensSold); // 使用 tokensSold 替代 totalSupply
    }

    //只读函数：发售状态辅助函数
    function timeRemaining() public view returns (uint256){
        // if(block.timestamp>=saleEndTime){
        //     return 0;
        // }
        // return saleEndTime-block.timestamp;

        // 用三元表达式替换
        return block.timestamp >= saleEndTime ? 0 : saleEndTime - block.timestamp;
    }
    function tokensAvailable() public view returns (uint256){
        return balanceOf[address(this)];
    }

    receive() external payable {
        buyTokens();
    }
}
