
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";//导入 Chainlink 的 AggregatorV3 接口
import "@openzeppelin/contracts/access/Ownable.sol";//导入 OpenZeppelin 的 Ownable 合约

contract CropInsurance is Ownable {
    AggregatorV3Interface private weatherOracle;
    //定义一个私有的天气语言机，类型为AggregatorV3Interface
    AggregatorV3Interface private ethUsdPriceFeed;
    //定义一个私有的ethUsd价格馈送，类型为 AggregatorV3Interface

    uint256 public constant RAINFALL_THRESHOLD = 500;//公共常量降雨量阈值500
    uint256 public constant INSURANCE_PREMIUM_USD = 10;//保险费，美元）为 10
    uint256 public constant INSURANCE_PAYOUT_USD = 50;//保险赔付额，美元）为 50

    mapping(address => bool) public hasInsurance;//映射，用户地址对应它是否有保险
    mapping(address => uint256) public lastClaimTimestamp;//用户地址对应上次请求时间戳

    event InsurancePurchased(address indexed farmer, uint256 amount);
    //定义一个保险购买事件（用户地址，金额）
    event ClaimSubmitted(address indexed farmer);
    //声明一个赔付提交（用户地址）
    event ClaimPaid(address indexed farmer, uint256 amount);
    //声明一个索赔完成（用户地址 金额）
    event RainfallChecked(address indexed farmer, uint256 rainfall);
    //声明一个降雨检查（用户地址，降雨量）

    constructor(address _weatherOracle, address _ethUsdPriceFeed) payable Ownable(msg.sender) {
        //_weatherOracle 降雨预言机地址  _ethUsdPriceFeed是 Chainlink 价格馈送的地址，可为我们提供 ETH → USD 的转换
        weatherOracle = AggregatorV3Interface(_weatherOracle);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    function purchaseInsurance() external payable {
        uint256 ethPrice = getEthPrice();
        uint256 premiumInEth = (INSURANCE_PREMIUM_USD * 1e18) / ethPrice;//保险费10美金换算成ETH

        require(msg.value >= premiumInEth, "Insufficient premium amount");//付款服用需要大于10美金
        require(!hasInsurance[msg.sender], "Already insured");//检查是否已经有保险了

        hasInsurance[msg.sender] = true;//定义用户已经买了保险
        emit InsurancePurchased(msg.sender, msg.value);//公告已（xxx地址，付款多少钱）
    }

    function checkRainfallAndClaim() external {//一个叫做检查降雨量和claim的函数，不返回值
        require(hasInsurance[msg.sender], "No active insurance");
        //需要满足msg.sender已经有保险
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days, "Must wait 24h between claims");
//24小时之后才能索赔
        (
            uint80 roundId,
            int256 rainfall,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = weatherOracle.latestRoundData();//调用weatherOracle合约

        require(updatedAt > 0, "Round not complete");
        require(answeredInRound >= roundId, "Stale data");

        uint256 currentRainfall = uint256(rainfall);
        emit RainfallChecked(msg.sender, currentRainfall);

        if (currentRainfall < RAINFALL_THRESHOLD) {//如果当前降雨量小于500
            lastClaimTimestamp[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);

            uint256 ethPrice = getEthPrice();
            uint256 payoutInEth = (INSURANCE_PAYOUT_USD * 1e18) / ethPrice;//赔付50美金换算成eth

            (bool success, ) = msg.sender.call{value: payoutInEth}("");//转账50美金的eth
            require(success, "Transfer failed");

            emit ClaimPaid(msg.sender, payoutInEth);//赔付成功
        }
    }

    function getEthPrice() public view returns (uint256) {
        //一个叫做getEthPrice（）的函数，公开可见返回价格
        (
            ,
            int256 price,
            ,
            ,
        ) = ethUsdPriceFeed.latestRoundData();///外部合约调用，调用了ethUsdPriceFeed地址

       require(price > 0, "Price feed returned invalid data");
        return uint256(price) * 1e10;
    }
    function checkDecimals() public view returns (uint8) {
    return ethUsdPriceFeed.decimals();
}

    function getCurrentRainfall() public view returns (uint256) {
       (
            ,
            int256 rainfall,
            ,
            ,
        ) = weatherOracle.latestRoundData();//外部合约调用，weatherOracle

        return uint256(rainfall);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);//合约里的钱提现
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {//获得余额
        return address(this).balance;
    }
}

