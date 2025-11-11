//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./MyToken.sol";

contract PreOrderToken is MyToken {

    uint256 public tokenPrice;     // 每个代币值多少 ETH（单位是 wei，1 ETH = 10¹⁸ wei）
    uint256 public saleStartTime;  // 表示发售开始和结束时间的时间戳
    uint256 public saleEndTime;    
    uint256 public minPurchase;    // 单笔交易中允许购买的最小和最大ETH额度
    uint256 public maxPurchase;
    uint256 public totalRaised;    // 目前为止接收的 ETH总额
    address public projectOwner;   // 发售结束后接收 ETH 的钱包地址
    bool public finalized = false; // 发售是否已经正式关闭
    bool private initialTransferDone = false;  // 用于确保合约在锁定转账前已收到所有代币

    // 当有人成功购买代币时触发。它会记录购买者、支付的 ETH 数量以及收到的代币数量。
    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount); 
    // 发售结束时触发。记录筹集的 ETH 总数和售出的代币数量。
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    constructor( 
        uint256 _intitialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    )MyToken(_intitialSupply){     // MyToken(_intitialSupply)⇒在后台帮你把全部代币分配给部署者（你）
        tokenPrice = _tokenPrice;  // 记录代币价格，单位是wei
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;
    
    
    // ！！！自动将所有代币转移至此合约用于发售
    _transfer(msg.sender, address(this), totalSupply);

    // 标记我们已经从部署者那里转移了代币
    initialTransferDone = true;
}

    // 检查发售是否正在进行
    function isSaleActive()public view returns(bool){
        return(!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    // 主要购买函数
    function buyTokens() public payable{
        require(isSaleActive(), "Sale is not active");    // 用辅助函数isSaleActive()检查发售是否正在进行中
        require(msg.value >= minPurchase, "Amount is below min purchase");
        require(msg.value <= maxPurchase, "Amount is above max purchase");
        uint256 tokenAmount = (msg.value * 10**uint256(decimals))/ tokenPrice;  // 计算要发多少代币:ETH 数量(msg.value) 乘以10 ** decimals,再除以每个代币的价格 tokenPrice 
        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");
        totalRaised+= msg.value;  // 更新已筹集的 ETH总额
        _transfer(address(this),msg.sender,tokenAmount); // 把代币转给买家
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);  // 事件：记录谁买了代币，花了多少ETH，收到多少代币
        
    }

    // 锁定直接转账（在发售进行期间暂时限制代币转账）
    // ！！！override：关键字，用于明确声明当前函数是对母合约（或接口）中同名函数的重写。
    function transfer(address _to, uint256 _value)public override returns(bool){
        // 检查三件事：发售尚未完成；交易不是由合约本身发起的；初始代币供应已经转移到合约中
        if(!finalized && msg.sender != address(this) && initialTransferDone){
            require(false, "Tokens are locked until sale is finalized");
        }
        
        // 正常转账
        // ！！！super：关键字，用于访问父合约的成员（函数或变量）。
        // ！！！调用母合约（MyToken）的 transfer 函数，并传入相同的参数 _to（接收地址）和 _value（转账数量）。
        return super.transfer(_to, _value);
    }

    // 锁定委托转账
    function transferFrom(address _from, address _to, uint256 _value)public override returns(bool){
        if(!finalized && _from != address(this)){
            require(false, "Tokens are locked until sale is finalized");
        }
        // 恢复默认转账逻辑
        return super.transferFrom(_from, _to, _value);
    }

    // 结束代币发售
    function finalizeSale() public payable{
        require(msg.sender == projectOwner, "Only owner can call this function"); // 只有项目所有者可以调用
        require(!finalized,"Sale is already finalized");  // 检查发售是否完成
        require (block.timestamp > saleEndTime, "Sale not finished yet"); // 确保发售期已经结束

        finalized = true; // 将发售标记为完成

        uint256 tokensSold = totalSupply - balanceOf[address(this)]; // 计算已售出的代币数量
        (bool sucess,) = projectOwner.call{value:  address(this).balance}(""); // 向项目所有者发送 ETH
        require(sucess, "Transfer failed"); // 用于确保这次发送没有静默失败（即失败但无报错提示）
        emit SaleFinalized(totalRaised, tokensSold); //事件（筹集的ETH总额，售出的代币数量）
    }

    // ！！！辅助函数：发售结束倒计时
    function timeRemaining() public view  returns(uint256){
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return (saleEndTime - block.timestamp);
    }

    // 辅助函数：可购买代币数量
    function tokensAvailable()public view returns(uint256){
        return balanceOf[address(this)];
    }

    // 接收直接发送的ETH
    // ！！！回退函数：ETH回退处理器，只要有人向该合约转入 ETH（即使只是从 MetaMask 或简单的钱包转账），合约都会在后台自动调用buyTokens()完成购买流程。
    receive() external payable{
        buyTokens();
    }
    }