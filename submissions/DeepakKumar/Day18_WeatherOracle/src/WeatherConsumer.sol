// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IWeatherOracle {
    function getRainfall() external view returns (int256, uint256);
}

contract WeatherConsumer {
    address public owner;
    IWeatherOracle public oracle;

    int256 public storedRainfall;
    uint256 public lastUpdated;

    event RainfallFetched(int256 rainfall, uint256 timestamp);

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IWeatherOracle(_oracle);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function updateFromOracle() external onlyOwner {
        (int256 rainfall, uint256 timestamp) = oracle.getRainfall();
        storedRainfall = rainfall;
        lastUpdated = timestamp;
        emit RainfallFetched(rainfall, timestamp);
    }

    function getStoredRainfall() external view returns (int256) {
        return storedRainfall;
    }
}
