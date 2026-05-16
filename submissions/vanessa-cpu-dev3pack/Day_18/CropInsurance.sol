// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWeatherOracle {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract CropInsurance {
    IWeatherOracle public weatherOracle;
    uint256 public constant RAINFALL_THRESHOLD = 50; // mm
    uint256 public constant PAYOUT_AMOUNT = 1 ether;
    uint256 public constant PREMIUM = 0.1 ether;

    mapping(address => bool) public policies;

    constructor(address _oracleAddress) {
        weatherOracle = IWeatherOracle(_oracleAddress);
    }

    // Fund the insurance pool
    receive() external payable {}

    function purchasePolicy() external payable {
        require(msg.value == PREMIUM, "Incorrect premium amount");
        require(!policies[msg.sender], "Policy already active");
        policies[msg.sender] = true;
    }

    function checkRainfallAndClaim() external {
        require(policies[msg.sender], "No active policy");

        (, int256 rainfall, , , ) = weatherOracle.latestRoundData();
        
        require(rainfall < int256(RAINFALL_THRESHOLD), "Rainfall sufficient, no payout");
        require(address(this).balance >= PAYOUT_AMOUNT, "Insufficient funds in contract");

        policies[msg.sender] = false; // Claim processed
        payable(msg.sender).transfer(PAYOUT_AMOUNT);
    }
}