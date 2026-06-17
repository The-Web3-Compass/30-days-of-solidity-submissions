// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract MockWeatherOracle is AggregatorV3Interface {
    address public immutable owner;
    uint8 private constant DECIMALS = 0;
    string private constant DESCRIPTION = "Mock/Rainfall/USD";
    uint256 private constant VERSION = 1;
    
    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _lastUpdateBlock;
    int256 private _cachedRainfall;

    error Unauthorized();
    error InvalidRainfall();

    event RainfallUpdated(uint80 indexed roundId, int256 rainfall, uint256 timestamp);
    event ManualRainfallSet(int256 rainfall, address setter);

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
        _roundId = 1;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
        _cachedRainfall = _generateRainfall();
    }

    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }

    function description() external pure override returns (string memory) {
        return DESCRIPTION;
    }

    function version() external pure override returns (uint256) {
        return VERSION;
    }

    function getRoundData(uint80 roundId_) external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        int256 rainfall = roundId_ == _roundId ? _cachedRainfall : _generateRainfall();
        return (roundId_, rainfall, _timestamp, _timestamp, roundId_);
    }

    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (_roundId, _cachedRainfall, _timestamp, _timestamp, _roundId);
    }
    
    function _generateRainfall() private view returns (int256) {
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
        uint256 randomFactor;
        unchecked {
            randomFactor = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.coinbase,
                blocksSinceLastUpdate,
                tx.gasprice,
                msg.sender
            ))) % 1000;
        }
        return int256(randomFactor);
    }
    
    function _updateRainfall() private {
        unchecked {
            _roundId++;
        }
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
        _cachedRainfall = _generateRainfall();
        
        emit RainfallUpdated(_roundId, _cachedRainfall, _timestamp);
    }
    
    function updateRandomRainfall() external {
        _updateRainfall();
    }

    function setManualRainfall(int256 rainfall) external onlyOwner {
        if (rainfall < 0 || rainfall > 2000) revert InvalidRainfall();
        
        _cachedRainfall = rainfall;
        _timestamp = block.timestamp;
        unchecked {
            _roundId++;
        }
        
        emit ManualRainfallSet(rainfall, msg.sender);
    }

    function getCurrentRainfall() external view returns (int256) {
        return _cachedRainfall;
    }

    function getLastUpdateInfo() external view returns (
        uint80 roundId,
        uint256 timestamp,
        uint256 blockNumber
    ) {
        return (_roundId, _timestamp, _lastUpdateBlock);
    }

    function simulateDrought() external onlyOwner {
        _cachedRainfall = 200; // Below threshold
        _timestamp = block.timestamp;
        unchecked {
            _roundId++;
        }
        emit ManualRainfallSet(_cachedRainfall, msg.sender);
    }

    function simulateHeavyRain() external onlyOwner {
        _cachedRainfall = 800; // Above threshold
        _timestamp = block.timestamp;
        unchecked {
            _roundId++;
        }
        emit ManualRainfallSet(_cachedRainfall, msg.sender);
    }
}