// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockWeatherOracle {
    uint8 public decimals = 0;
    string public description = "MOCK/RAINFALL/USD";
    uint80 public roundId = 1;
    uint256 public lastUpdate;
    
    event RainfallUpdated(uint256 rainfall, uint256 timestamp);
    
    function latestRoundData() external returns (
        uint80 _roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        uint256 randomRainfall = generateRandomRainfall();
        
        roundId++;
        lastUpdate = block.timestamp;
        
        emit RainfallUpdated(randomRainfall, block.timestamp);
        
        return (
            roundId,
            int256(randomRainfall),
            block.timestamp - 3600,
            block.timestamp,
            roundId
        );
    }
    
    function generateRandomRainfall() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp, 
            block.difficulty,
            msg.sender
        ))) % 1000;
    }
    
    function updateRainfall() external {
        roundId++;
        lastUpdate = block.timestamp;
    }
}

contract MockEthPriceOracle {
    uint8 public decimals = 8;
    string public description = "MOCK/ETH/USD";
    
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            1,
            int256(2500 * 10**8),
            block.timestamp - 3600,
            block.timestamp,
            1
        );
    }
}

contract CropInsurance {
    address public owner;
    MockWeatherOracle public weatherOracle;
    MockEthPriceOracle public priceOracle;
    
    uint256 public constant RAINFALL_THRESHOLD = 500;
    uint256 public constant PREMIUM_USD = 10 * 10**18;
    uint256 public constant PAYOUT_USD = 50 * 10**18;
    
    mapping(address => bool) public hasInsurance;
    mapping(address => uint256) public lastClaimTime;
    
    event InsurancePurchased(address farmer, uint256 premium);
    event ClaimSubmitted(address farmer, uint256 rainfall);
    event ClaimPaid(address farmer, uint256 payout);
    
    constructor(address _weatherOracle, address _priceOracle) {
        owner = msg.sender;
        weatherOracle = MockWeatherOracle(_weatherOracle);
        priceOracle = MockEthPriceOracle(_priceOracle);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    function purchaseInsurance() external payable {
        require(!hasInsurance[msg.sender], "Already insured");
        
        uint256 ethPrice = getEthPrice();
        uint256 requiredEth = (PREMIUM_USD * 10**18) / ethPrice;
        
        require(msg.value >= requiredEth, "Insufficient premium");
        
        hasInsurance[msg.sender] = true;
        
        if (msg.value > requiredEth) {
            payable(msg.sender).transfer(msg.value - requiredEth);
        }
        
        emit InsurancePurchased(msg.sender, requiredEth);
    }
    
    function checkAndClaim() external {
        require(hasInsurance[msg.sender], "No insurance");
        require(block.timestamp >= lastClaimTime[msg.sender] + 1 days, "Wait 24h");
        
        (, int256 rainfall, , , ) = weatherOracle.latestRoundData();
        uint256 currentRainfall = uint256(rainfall);
        
        emit ClaimSubmitted(msg.sender, currentRainfall);
        
        if (currentRainfall < RAINFALL_THRESHOLD) {
            lastClaimTime[msg.sender] = block.timestamp;
            
            uint256 ethPrice = getEthPrice();
            uint256 payoutEth = (PAYOUT_USD * 10**18) / ethPrice;
            
            require(address(this).balance >= payoutEth, "Insufficient contract balance");
            
            payable(msg.sender).transfer(payoutEth);
            emit ClaimPaid(msg.sender, payoutEth);
        }
    }
    
    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceOracle.latestRoundData();
        return uint256(price);
    }
    
    function getCurrentRainfall() external returns (uint256) {
        (, int256 rainfall, , , ) = weatherOracle.latestRoundData();
        return uint256(rainfall);
    }
    
    function getPremiumInEth() external view returns (uint256) {
        uint256 ethPrice = getEthPrice();
        return (PREMIUM_USD * 10**18) / ethPrice;
    }
    
    function getPayoutInEth() external view returns (uint256) {
        uint256 ethPrice = getEthPrice();
        return (PAYOUT_USD * 10**18) / ethPrice;
    }
    
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    receive() external payable {}
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}