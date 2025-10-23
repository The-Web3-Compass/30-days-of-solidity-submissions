// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract CropInsurance {
    AggregatorV3Interface private immutable weatherOracle;
    AggregatorV3Interface private immutable ethUsdPriceFeed;
    address public immutable owner;

    uint256 public constant RAINFALL_THRESHOLD = 500;
    uint256 public constant INSURANCE_PREMIUM_USD = 10;
    uint256 public constant INSURANCE_PAYOUT_USD = 50;
    uint256 public constant MAX_DATA_STALENESS = 3600;
    uint256 public constant CLAIM_COOLDOWN = 1 days;

    mapping(address => bool) public hasInsurance;
    mapping(address => uint256) public lastClaimTimestamp;
    mapping(address => bool) private _claiming;

    error InvalidAddress();
    error InsufficientPremium(uint256 required, uint256 provided);
    error AlreadyInsured();
    error NoInsurance();
    error ClaimCooldown(uint256 timeLeft);
    error AlreadyClaiming();
    error StaleOracleData();
    error InsufficientBalance();
    error TransferFailed();
    error Unauthorized();
    error InvalidPrice();

    event InsurancePurchased(address indexed farmer, uint256 amount);
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer, uint256 amount);
    event RainfallChecked(address indexed farmer, uint256 rainfall);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _weatherOracle, address _ethUsdPriceFeed) payable {
        if (_weatherOracle == address(0) || _ethUsdPriceFeed == address(0)) {
            revert InvalidAddress();
        }
        weatherOracle = AggregatorV3Interface(_weatherOracle);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        owner = msg.sender;
    }
    
    function purchaseInsurance() external payable {
        if (hasInsurance[msg.sender]) revert AlreadyInsured();
        
        uint256 ethPrice = getEthPrice();
        uint256 premiumInEth;
        unchecked {
            premiumInEth = (INSURANCE_PREMIUM_USD * 1e18) / ethPrice;
        }

        if (msg.value < premiumInEth) {
            revert InsufficientPremium(premiumInEth, msg.value);
        }

        hasInsurance[msg.sender] = true;
        emit InsurancePurchased(msg.sender, msg.value);
    }
    
    function checkRainfallAndClaim() external {
        if (!hasInsurance[msg.sender]) revert NoInsurance();
        if (_claiming[msg.sender]) revert AlreadyClaiming();
        
        uint256 nextClaimTime = lastClaimTimestamp[msg.sender] + CLAIM_COOLDOWN;
        if (block.timestamp < nextClaimTime) {
            revert ClaimCooldown(nextClaimTime - block.timestamp);
        }
        
        _claiming[msg.sender] = true;
        
        (
            uint80 roundId,
            int256 rainfall,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = weatherOracle.latestRoundData();

        if (updatedAt == 0 || answeredInRound < roundId || 
            block.timestamp - updatedAt > MAX_DATA_STALENESS) {
            revert StaleOracleData();
        }

        uint256 currentRainfall = uint256(rainfall);
        emit RainfallChecked(msg.sender, currentRainfall);

        if (currentRainfall < RAINFALL_THRESHOLD) {
            lastClaimTimestamp[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);

            uint256 ethPrice = getEthPrice();
            uint256 payoutInEth;
            unchecked {
                payoutInEth = (INSURANCE_PAYOUT_USD * 1e18) / ethPrice;
            }
            
            if (address(this).balance < payoutInEth) revert InsufficientBalance();

            (bool success, ) = msg.sender.call{value: payoutInEth}("");
            if (!success) revert TransferFailed();

            emit ClaimPaid(msg.sender, payoutInEth);
        }
        
        _claiming[msg.sender] = false;
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        if (price <= 0) revert InvalidPrice();
        unchecked {
            return uint256(price) * 1e10;
        }
    }

    function getCurrentRainfall() public view returns (uint256) {
        (, int256 rainfall, , , ) = weatherOracle.latestRoundData();
        return uint256(rainfall);
    }

    function getPremiumInEth() external view returns (uint256) {
        uint256 ethPrice = getEthPrice();
        unchecked {
            return (INSURANCE_PREMIUM_USD * 1e18) / ethPrice;
        }
    }

    function getPayoutInEth() external view returns (uint256) {
        uint256 ethPrice = getEthPrice();
        unchecked {
            return (INSURANCE_PAYOUT_USD * 1e18) / ethPrice;
        }
    }

    function getTimeUntilNextClaim(address farmer) external view returns (uint256) {
        uint256 nextClaimTime = lastClaimTimestamp[farmer] + CLAIM_COOLDOWN;
        return block.timestamp >= nextClaimTime ? 0 : nextClaimTime - block.timestamp;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert InsufficientBalance();
        
        (bool success, ) = owner.call{value: balance}("");
        if (!success) revert TransferFailed();
        
        emit FundsWithdrawn(owner, balance);
    }

    receive() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}