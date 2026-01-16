// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./Day18-MockWeatherOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CropInsurance is Ownable{
    AggregatorV3Interface private weatherOracle;
    AggregatorV3Interface private ethUsdPriceFeed;

    uint256 public constant RAINFALL_THRESHOLD = 500;//降雨量门槛
    uint256 public constant INSURANCE_PREMIUM_USD = 10;//投保金额
    // 是为了让正常市场汇率兑换，不受以太币价格影响
    uint256 public constant INSURANCE_PAYOUT_USD = 50;//配保

    mapping (address => bool) public hasInsurance;//是否投保了
    mapping (address => uint256) public lastClaimTimestamp;// 投保时间


    event InsurancePurchased(address indexed farmer, uint256 amount);//成功投保事件
    event RainfallCheck(address indexed farmer, uint256 rainfall);//降雨量检查
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer, uint256 amount);//已经赔付

    // 构造函数
    constructor(address _weatherOracle, address _ethUsdPriceFeed) payable Ownable(msg.sender){
        weatherOracle = AggregatorV3Interface(_weatherOracle);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    // 购买保险
    function purchaseInsurance()external payable {
        uint256 ethPrice = getEthPrice();
        uint256 premiumInEth = (INSURANCE_PREMIUM_USD * 1e18)/ethPrice;
        require(msg.value >= premiumInEth, "No enough money");
        require(!hasInsurance[msg.sender]==true, "Already insured");//已经投保不能重复投保

        hasInsurance[msg.sender] = true;
        emit InsurancePurchased(msg.sender, msg.value);
        
    }

    

    //获取金额
    function getEthPrice() public view returns(uint256) {
        ( , int256 price, , ,) = ethUsdPriceFeed.latestRoundData();
        return uint256(price);
    }

    // 检查降雨量
    function checkRainfallAndClaim() external {
        require(hasInsurance[msg.sender],"No active insurance");//检查用户是否投保
        //投保之后需要有一天的冷却期
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days, "Must wait 24h between claims");
        // 提取最新的降雨数据
        (uint80 roundId, int rainfall, , uint256 updatedAt, uint80 answeredInRound) = weatherOracle.latestRoundData();

        require(updatedAt > 0, "Round not complete");
        require(answeredInRound >= roundId, "Stale data");

        uint256 currentRainfall = uint256(rainfall);
        emit RainfallCheck(msg.sender,currentRainfall);

        
        if (currentRainfall < RAINFALL_THRESHOLD) {//降雨量低于干旱阈值
            lastClaimTimestamp[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);
            
            uint256 ethPrice = getEthPrice();
            uint256 payoutInEth = (INSURANCE_PAYOUT_USD * 1e18) / ethPrice;
            
            (bool success, ) = msg.sender.call{value: payoutInEth}("");
            require(success, "Transfer failed");

            
            emit ClaimPaid(msg.sender, payoutInEth);
        }
    }
    //任何人都可以查看当前降雨量
    function getCurrentRainfall() public view returns (uint256) {
        (, int256 rainfall, , , ) = weatherOracle.latestRoundData();
        return uint256(rainfall);
    }
    //退款
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}