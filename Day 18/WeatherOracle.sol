// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 🌤 Oracle interface
interface IWeatherOracle {
    function getRainfallData(string calldata location) external view returns (uint256);
}

//  Crop insurance contract using weather data
contract WeatherOracle {
    address public owner;
    IWeatherOracle public oracle;
    uint256 public rainfallThreshold = 50; // mm of rain required
    mapping(address => bool) public insuredFarmers;
    mapping(address => bool) public hasClaimed;

    event InsuranceBought(address indexed farmer);
    event InsuranceClaimed(address indexed farmer, uint256 payout);
    event OracleUpdated(address indexed newOracle);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IWeatherOracle(_oracle);
    }

    // Buy insurance
    function buyInsurance() external payable {
        require(msg.value == 0.01 ether, "Premium is 0.01 ETH");
        insuredFarmers[msg.sender] = true;
        emit InsuranceBought(msg.sender);
    }

    // Claim if rainfall < threshold
    function claim(string calldata location) external {
        require(insuredFarmers[msg.sender], "Not insured");
        require(!hasClaimed[msg.sender], "Already claimed");

        uint256 rainfall = oracle.getRainfallData(location);
        require(rainfall < rainfallThreshold, "Conditions not met");

        hasClaimed[msg.sender] = true;
        payable(msg.sender).transfer(0.05 ether); // Example payout
        emit InsuranceClaimed(msg.sender, 0.05 ether);
    }

    // Update oracle if needed
    function updateOracle(address _newOracle) external onlyOwner {
        oracle = IWeatherOracle(_newOracle);
        emit OracleUpdated(_newOracle);
    }

    // Deposit funds to cover payouts
    receive() external payable {}
}
