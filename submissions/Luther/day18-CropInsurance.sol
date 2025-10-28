//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable {      //定义合约并继承 Ownable，部署者（通过构造函数调用
    AggregatorV3Interface private weatherOracle;     //类型为 Chainlink Aggregator 接口，用来读取降雨数据
    AggregatorV3Interface private ethUsdPriceFeed;     //声明另一个 Chainlink 接口实例，用于读取 ETH/USD 价格（用于 USD↔ETH 的换算）

    uint256 public constant RAINFALL_THRESHOLD = 500;     //阈值（单位：毫米），若降雨小于 500mm 则触发赔付逻辑
    uint256 public constant INSURANCE_PREMIUM_USD = 10;     //保费以美元计（$10）
    uint256 public constant INSURANCE_PAYOUT_USD = 50;     //赔付额度以美元计（$50）

    mapping(address => bool) public hasInsurance;     //记录某地址是否已购买保险（布尔）
    mapping(address => uint256) public lastClaimTimestamp;     //记录上次成功提交 claim 的时间戳（用于 24h 冷却）

    //InsurancePurchased：记录保单购买
    event InsurancePurchased(address indexed farmer, uint256 amount);   

    //ClaimSubmitted：提交理赔的记录（在找到低雨量时发出）
    event ClaimSubmitted(address indexed farmer);     

    //ClaimPaid：赔付成功后发出（包含实际支付的 Wei 数量）
    event ClaimPaid(address indexed farmer, uint256 amount);

    //RainfallChecked：每次检查降雨值时记录，用于审计/前端展示
    event RainfallChecked(address indexed farmer, uint256 rainfall);

    constructor(address _weatherOracle, address _ethUsdPriceFeed) payable Ownable(msg.sender) {

        //将传入地址转换（类型转换）为 AggregatorV3Interface 接口，方便后续通过 weatherOracle.latestRoundData() 调用
        weatherOracle = AggregatorV3Interface(_weatherOracle);

        //同上，为 ETH/USD 价格 feed 做接口包装
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    
    function purchaseInsurance() external payable {

        //调用 getEthPrice()（下文）读取 Chainlink 的 ETH/USD 价格
        uint256 ethPrice = getEthPrice();

        //将以美元计的保费 INSURANCE_PREMIUM_USD（$10）转换为 wei（ETH 的最小单位）
        uint256 premiumInEth = (INSURANCE_PREMIUM_USD * 1e18) / ethPrice;
        
        //检查调用者付的 ETH 是否至少等于所需保费（wei
        require(msg.value >= premiumInEth, "Insufficient premium amount");

        //防止同一地址重复购买（简单的单保单模型）
        require(!hasInsurance[msg.sender], "Already insured");

        //将购买状态设置为已投保
        hasInsurance[msg.sender] = true;

        //发出事件记录购买者和支付的 msg.value
        emit InsurancePurchased(msg.sender, msg.value);
    }

    //外部可调用（任何地址），但后面有第一步检查
    function checkRainfallAndClaim() external {

        //校验发起者必须已购买保险（hasInsurance 为 true），否则报错
        require(hasInsurance[msg.sender], "No active insurance");

        //冷却时间：同一地址两次理赔请求必须至少间隔 24 小时（用 1 days 表达）。防止短时间内刷取多次赔付
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days, "Must wait 24h between claims");

        //Oracle 调用
        //通过 weatherOracle.latestRoundData() 拉取最新一轮数据并解构赋值
        (
            uint80 roundId,
            int256 rainfall,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = weatherOracle.latestRoundData();

        //确保 oracle 的 updatedAt 字段非零（表示这一轮已完成且时间戳有效）
        //链上某些 aggregator 在某些情况下会返回 updatedAt == 0 表示数据不可用或轮次未成熟
        require(updatedAt > 0, "Round not complete");

        //验证 answeredInRound >= roundId：
        //Chainlink 建议用此检查确保 answer 属于或覆盖请求的 roundId（防止回滚等边缘情况）
        //如果 answeredInRound < roundId，表示当前返回的是过去轮次的答案（过期/不完整）
        require(answeredInRound >= roundId, "Stale data");

        //将 int256 的 rainfall 强转为 uint256
        uint256 currentRainfall = uint256(rainfall);

        //记录检查行为与数值，便于链下审计和 UI 展示
        emit RainfallChecked(msg.sender, currentRainfall);

        //赔付条件：当前降雨低于阈值才触发赔付流程
        if (currentRainfall < RAINFALL_THRESHOLD) {

            //记录本次理赔的时间戳，作为下次冷却的基准
            lastClaimTimestamp[msg.sender] = block.timestamp;

            //记录“提交理赔”事件（可作为链下审计）
            emit ClaimSubmitted(msg.sender);
            
            //再次调用 chainlink ETH/USD 价格，用于把 USD 赔付转换成 ETH
            uint256 ethPrice = getEthPrice();

            //同样的单位换算：给定 $50，计算等值的 wei
            uint256 payoutInEth = (INSURANCE_PAYOUT_USD * 1e18) / ethPrice;
            
            //采用低级 call 将 ETH 发送到 msg.sender。call 是推荐的发送方式（可以绕过 2300 gas 限制），并允许接收合约执行其回退逻辑
            (bool success, ) = msg.sender.call{value: payoutInEth}("");

            //检查转账成功与否；失败则 revert（回退整个事务，包括对 lastClaimTimestamp 的写入会回退
            require(success, "Transfer failed");

            //记录已支付赔款（单位 wei）
            emit ClaimPaid(msg.sender, payoutInEth);
        }
    }

    //只读取Chainlink的ETH/USD价格，不更改合约内容
    function getEthPrice() public view returns (uint256) {
        (
            ,
            int256 price,
            ,
            ,
        ) = ethUsdPriceFeed.latestRoundData();    //从Chainlink问了五个数据，但只要第二个：ETH的美元价值

        return uint256(price);     //强制转换成无符号整数
    }

    function getCurrentRainfall() public view returns (uint256) {
        (
            ,
            int256 rainfall,
            ,
            ,
        ) = weatherOracle.latestRoundData();

        return uint256(rainfall);
    }

    //只有合约所有者可以调用（onlyOwner 来自 Ownable）
    function withdraw() external onlyOwner {

        //将合约全部余额一次性转账给 owner
        //transfer 限制了 2300 gas 的转发 => 如果 owner() 是合约且 fallback 需要更多 gas，transfer 可能失败并 revert
        //address(this).balance 获取合约当前全部 ETH 余额
        payable(owner()).transfer(address(this).balance);
    }

    //Solidity 的 receive 回退函数，用于接收裸 ETH 转账（当没有 calldata 时触发）
    //receive 允许任意地址向合约转账 ETH，便于管理员或第三方注资
    receive() external payable {}

    //公共可见的合约余额查询（以 wei 返回）
    //便于前端或审计查询合约资金是否足够覆盖潜在赔付
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}


