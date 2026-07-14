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

// Farmers pay ETH for coverage: if rainfall drops below a threshold, they get a payout automatically

contract CropInsurance {
    IWeatherOracle public weatherOracle;
    uint256 public constant RAINFALL_THRESHOLD = 50; // mm
    uint256 public constant PAYOUT_AMOUNT = 1 ether;
    uint256 public constant PREMIUM = 0.1 ether;

    mapping(address => bool) public policies;
    
    constructor(address _oracleAddress) {
        require(_oracleAddress != address(0), "Invalid oracle address");
        weatherOracle = IWeatherOracle(_oracleAddress);

    receive() external payable {} // fund the insurance pool

    function purchasePolicy() external payable {
        require(msg.value == PREMIUM, "Incorrect premium amount");
        require(!policies[msg.sender], "Policy already purchased");

            (, int256 rainfall, , , ) = weatherOracle.latestRoundData();
            require(rainfall >= int256(RAINFALL_THRESHOLD), "Cannot buy during payout condition");
            policies[msg.sender] = true;
    }

    function checkRainfallAndClaim() external {
        require(policies[msg.sender], "no active policy");

        (, int256 rainfall, , , ) = weatherOracle.latestRoundData();

        require(rainfall < int256(RAINFALL_THRESHOLD), "Rainfall above threshold, no payout");
        require(address(this).balance >= PAYOUT_AMOUNT, "Insufficient funds in insurance pool");

        policies[msg.sender] = false; // Claim processed
        (bool success, ) = payable(msg.sender).call{value: PAYOUT_AMOUNT}("");
                require(success, "Payout transfer failed");
    }
}