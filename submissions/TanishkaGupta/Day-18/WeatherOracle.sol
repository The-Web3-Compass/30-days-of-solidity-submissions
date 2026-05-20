// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WeatherOracle {

    address public oracle; // trusted data provider
    string public weather; // latest weather data

    event WeatherUpdated(string newWeather);

    constructor() {
        oracle = msg.sender; // deployer acts as oracle
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only oracle can update data");
        _;
    }

    // Oracle updates weather data (simulating off-chain input)
    function updateWeather(string calldata _weather) external onlyOracle {
        weather = _weather;
        emit WeatherUpdated(_weather);
    }

    // Public function to read weather
    function getWeather() external view returns (string memory) {
        return weather;
    }

    // Change oracle (optional)
    function setOracle(address _newOracle) external onlyOracle {
        require(_newOracle != address(0), "Invalid address");
        oracle = _newOracle;
    }
}