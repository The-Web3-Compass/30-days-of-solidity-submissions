// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract WeatherOracleMock {
    address public owner;
    int256 private rainfall; // e.g. rainfall in mm * 100
    uint256 public lastUpdated;

    event RainfallUpdated(int256 rainfall, uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function updateRainfall(int256 _rainfall) external onlyOwner {
        rainfall = _rainfall;
        lastUpdated = block.timestamp;
        emit RainfallUpdated(_rainfall, block.timestamp);
    }

    function getRainfall() external view returns (int256, uint256) {
        return (rainfall, lastUpdated);
    }
}
