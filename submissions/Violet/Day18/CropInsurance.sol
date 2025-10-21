// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract CropInsurance is Ownable {
    AggregatorV3Interface public weatherOracle;
    AggregatorV3Interface public ethUsdPriceFeed;

    uint256 public constant RAINFALL_THRESHOLD = 500; // 降雨量阈值 (mm)
    uint256 public constant INSURANCE_PREMIUM_USD = 10; // 保费 (10美元)
    uint256 public constant INSURANCE_PAYOUT_USD = 50;  // 赔付款 (50美元)

    mapping(address => bool) public hasInsurance;
    mapping(address => uint256) public lastClaimTimestamp;

    event InsurancePurchased(address indexed farmer, uint256 ethAmount);
    event ClaimPaid(address indexed farmer, uint256 payoutAmount);

    /**
     * @param _weatherOracleAddress 模拟天气预言机的地址。
     * @param _ethUsdPriceFeedAddress Chainlink ETH/USD 价格源的地址。
     */
    constructor(address _weatherOracleAddress, address _ethUsdPriceFeedAddress) payable Ownable(msg.sender) {
        weatherOracle = AggregatorV3Interface(_weatherOracleAddress);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeedAddress);
    }

    /**
     * @dev 农户购买保险。
     */
    function purchaseInsurance() external payable {
        uint256 ethPrice = getLatestEthPrice();
        // 计算10美元等值的ETH (wei)
        uint256 premiumInEth = (INSURANCE_PREMIUM_USD * 1e18) / ethPrice;

        require(msg.value >= premiumInEth, "Insufficient premium amount");
        require(!hasInsurance[msg.sender], "Already insured");

        hasInsurance[msg.sender] = true;
        emit InsurancePurchased(msg.sender, msg.value);
    }

    /**
     * @dev 农户检查天气并尝试发起理赔。
     */
    function checkRainfallAndClaim() external {
        require(hasInsurance[msg.sender], "No active insurance");
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days, "Must wait 24h between claims");

        uint256 currentRainfall = getLatestRainfall();

        // 检查是否满足干旱条件
        if (currentRainfall < RAINFALL_THRESHOLD) {
            lastClaimTimestamp[msg.sender] = block.timestamp;
            
            uint256 ethPrice = getLatestEthPrice();
            // 计算50美元等值的ETH (wei)
            uint256 payoutInEth = (INSURANCE_PAYOUT_USD * 1e18) / ethPrice;
            
            // 确保合约有足够的资金来支付
            require(address(this).balance >= payoutInEth, "Insufficient funds for payout");

            (bool success, ) = msg.sender.call{value: payoutInEth}("");
            require(success, "Transfer failed");

            emit ClaimPaid(msg.sender, payoutInEth);
        }
    }

    /**
     * @dev 从Chainlink价格源获取最新的ETH价格 (返回带8位小数的USD价格)。
     */
    function getLatestEthPrice() public view returns (uint256) {
        (
            , // roundId
            int256 price,
            , // startedAt
            , // updatedAt
              // answeredInRound
        ) = ethUsdPriceFeed.latestRoundData();
        
        // Chainlink ETH/USD 价格有8位小数，我们直接返回这个带小数的整数
        return uint256(price);
    }

    /**
     * @dev 从我们的天气预言机获取最新的降雨量数据。
     */
    function getLatestRainfall() public view returns (uint256) {
        (
            , // roundId
            int256 rainfall,
            , // startedAt
            , // updatedAt
              // answeredInRound
        ) = weatherOracle.latestRoundData();

        return uint256(rainfall);
    }
    
    /**
     * @dev 允许合约所有者提取合约中剩余的ETH (例如，未被理赔的保费)。
     */
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // 允许合约直接接收ETH
    receive() external payable {}
}
