//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day12.sol";

contract PreOrderToken is SimpleERC20 {

    uint256 public tokenPrice;     //声明公开的无符号整数状态变量 tokenPrice，表示一个代币的价格（通常以 wei 为单位）
    uint256 public saleStartTime;     //状态变量 saleStartTime：保存销售开始的区块时间戳（block.timestamp 单位为秒）。公开可读
    uint256 public saleEndTime;     //状态变量 saleEndTime：保存销售结束的时间戳。公开可读
    uint256 public minPurchase;     //状态变量 minPurchase：记录单笔最小购买金额（以 wei 为单位）。公开可读
    uint256 public maxPurchase;     //状态变量 maxPurchase：记录单笔最大购买金额（以 wei 为单位）。公开可读
    uint256 public totalRaised;     //态变量 totalRaised：累计记录合约已收到的以太币总额（以 wei 为单位）。公开可读
    address public projectOwner;     //状态变量 projectOwner：保存项目方或合约拥有者地址，通常用于权限检查（例如提取募集资金）。公开可读
    bool public finalized = false;     //布尔型状态变量 finalized：指示销售是否已被最终确认/结束。初始化为 false。公开可读
    bool private initialTransferDone = false;    //私有布尔变量 initialTransferDone：用于标记合约部署后的初始代币转移是否已完成，初始值 false。private 表示只有合约自身可访问（包括继承合约不能直接访问）

    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokeyAmount);     //声明事件 TokensPurchased，用于在链上记录购买发生：购买者地址、支付的以太数量、以及获得代币数量
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);     //声明事件 SaleFinalized，在销售结束并结算后触发，记录总募集的以太和总售出代币数。便于链上审计

    constructor(

        uint256 _initialSupply,     //构造函数参数：_initialSupply 表示初始代币供应量（通常以“最小单位”前还要乘以 10**decimals — 但这里传参含义依赖父合约）
        uint256 _tokenPrice,     //构造函数参数：代币单价（以 wei 表示）
        uint256 _saleDurationInSeconds,     //构造函数参数：销售持续时间，单位为秒，合约会用它来设置 saleEndTime
        uint256 _minPurchase,     //构造函数参数：每笔购买的最小以太数（wei）
        uint256 _maxPurchase,     //构造函数参数：每笔购买的最大以太数（wei）
        address _projectOwner     //构造函数参数：项目方地址（合约部署者可能并非项目方，所以传入参数）
    ) SimpleERC20(_initialSupply) {     //结束构造函数参数列表并调用父合约 SimpleERC20 的构造函数，传入 _initialSupply
        tokenPrice = _tokenPrice;     //在构造函数体内，将传入的 _tokenPrice 保存到合约状态变量 tokenPrice
        saleStartTime = block.timestamp;     //将 saleStartTime 设置为当前区块时间（部署时刻），表示预售从部署时刻开始
        saleEndTime = block.timestamp;     //saleDurationInSeconds;     将 saleEndTime 设置为当前时间加上传入的持续秒数，确定销售结束时刻
        minPurchase = _minPurchase;     //将最小购买金额保存到状态变量 minPurchase
        maxPurchase = _maxPurchase;     //将最大购买金额保存到状态变量 maxPurchase
        projectOwner = _projectOwner;     //将传入的项目方地址赋给 projectOwner，后续权限检查将基于此地址

        _transfer(msg.sender, address(this), _initialSupply);     //调用父合约或当前合约的内部 _transfer 函数，把 _initialSupply 从 msg.sender（父构造中可能已经把代币给了 msg.sender）转移到合约自身地址 address(this)，以便合约保有售卖用的代币库存

        initialTransferDone = true;     //将 initialTransferDone 标记为 true，表示初始转移已经完成。后续逻辑可用它来允许或禁止某些操作

    }

function isSaleActive() public view returns (bool) {     //定义公开只读函数 isSaleActive()，返回是否当前处于销售活动期（布尔）。view 表示不会修改链上状态
    return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);     //返回 true 的条件：销售未被 finalised、当前时间大于等于开始时间并且不晚于结束时间。三者都满足则返回 true
}

function buyTokens() public payable {    // 定义公开并可接收以太的函数 buyTokens()，调用者可以通过 msg.value 支付以太来购买代币。payable 允许函数接收以太
    require(isSaleActive(), "Sale is not active");     //检查销售当前是否激活；若不激活则回退并返回错误信息
    require(msg.value >= minPurchase, "Amount is below minimum purchase");     //检查本次支付金额不得低于 minPurchase，否则回退
    require(msg.value <= maxPurchase, "Amount exceeds maximum purchase");     //检查本次支付金额不得超过 maxPurchase，否则回退

    uint256 tokenAmount = (msg.value * 10**uint256(decimals)) / tokenPrice;     //计算应付代币数量：将收到的以太 msg.value 乘以 10**decimals（把以太金额换算成代币的最小单位），再除以 tokenPrice
    require(balanceOf[address(this)] >= tokenAmount, "Not enough token left for sale");     //检查合约地址持有的代币是否足以支付本次购买

    totalRaised += msg.value;     //将本次收到的以太累加到 totalRaised
    _transfer(address(this), msg.sender, tokenAmount);     //调用内部 _transfer 函数，从合约地址 address(this) 给买家 msg.sender 转移 tokenAmount 代币。依赖父合约实现 _transfer
    emit TokensPurchased(msg.sender, msg.value, tokenAmount);     //触发事件 TokensPurchased，记录购买者地址、支付的以太、以及获得的代币数量  
}

function transfer(address _to, uint256 _value) public override returns (bool) {     //写父合约的 transfer 函数（override），并保持相同签名。允许合约添加前置检查或限制
    if (!finalized && msg.sender != address(this) && initialTransferDone) {     //如果销售未终结 !finalized 且调用者不是合约自身 msg.sender != address(this) 且初始转移已完成 initialTransferDone，则进入条件体。意图是：在售卖期间锁定普通持有者的转账（只允许合约相关转账）
        require(false, "Tokens are locked until sale is finalized");     //直接 require(false, ...) 会始终回退并显示消息，达到锁定转账的目的
    }
    return super.transfer(_to, _value);     //调用父合约实现的 transfer（SimpleERC20.transfer），执行实际转账逻辑，并返回其结果
}

function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {     //写父合约的 transferFrom 函数，允许第三方按照 allowance 把代币从 _from 转出
    if (!finalized && _from != address(this)) {     //在销售未结束并且转出方不是合约地址时，进入锁定逻辑，意图防止在售卖期间普通地址被转出
        require(false, "Tokens are locked until sale is finalizd");     //直接回退并给出消息，阻止 transferFrom
    }
    return super.transferFrom(_from, _to, _value);     //调用父合约的 transferFrom 来执行实际授权转账逻辑，并返回结果
}

function finalizeSale() public payable {     //定义 finalizeSale 函数，用于项目方在销售期结束后做最终结算
    require(msg.sender == projectOwner, "Only Owner can call the function");     //权限检查：仅允许 projectOwner 调用该函数，否则回退
    require(!finalized, "Sale already finalized");     //检查是否尚未 finalize，防止重复调用
    require(block.timestamp > saleEndTime, "Sale not finished yet");     //检查当前时间必须晚于 saleEndTime，即销售期已结束才允许 finalize

    finalized = true;     //将 finalized 标记为 true，表示销售已经最终结束，之后的锁定逻辑会解除
    uint256 tokensSold = totalSupply - balanceOf[address(this)];     //计算已售出代币数：使用 totalSupply 减去合约自身持有的库存 balanceOf[address(this)]

    (bool success, ) = projectOwner.call{value: address(this).balance}("");     ///用低级 call 将合约当前持有的以太（address(this).balance）发送给 projectOwner。call 返回一个 success 布尔和数据
    require(success, "Transfer to project owner failed");     //检查 call 是否成功，若失败则回退并提示错误信息

    emit SaleFinalized(totalRaised, tokensSold);     //触发 SaleFinalized 事件，记录此次 finalize 时总募集金额 totalRaised 和计算的已售出代币 tokensSold
}

function timeRemaining() public view returns (uint256) {     //定义公开只读函数 timeRemaining()，用于返回到销售结束剩余的秒数（若已结束则返回 0）
    if (block.timestamp >= saleEndTime) {     //断当前时间是否已经达到或超过 saleEndTime
        return 0;     //若已到或超过结束时间，返回 0（表示无剩余时间）
}
    return saleEndTime - block.timestamp;     //若尚未到结束时间，返回剩余秒数（saleEndTime - now）

}

function tokenAvailable() public view returns (uint256) {     //定义公开只读函数 tokenAvailable()，返回合约当前持有可售代币数量
    return balanceOf[address(this)];     //返回合约地址在 balanceOf 映射中的余额，即可供出售的代币数量
}

receive() external payable {     //定义 receive 特殊函数：当合约接收到没有 calldata 的以太（例如直接 send 或 transfer）时会被调用。external payable 是必须的签名
    buyTokens();     //在 receive 中调用 buyTokens()，使得直接向合约发送以太等同于购买代币的操作
}

}