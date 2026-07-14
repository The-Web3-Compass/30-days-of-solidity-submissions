
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

// Interface for Chainlink Aggregators (Simplified for the task)
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// MockWeatherOracle.sol
contract MockWeatherOracle is AggregatorV3Interface {
    uint80 private _roundId;
    uint256 private _timestamp;

    constructor() {
        _roundId = 1;
        _timestamp = block.timestamp;
    }

    // Force an update to the round for testing purposes
    function updateRound() external {
        _roundId++;
        _timestamp = block.timestamp;
    }

    function latestRoundData()
        external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }

    function _rainfall() public view returns (int256) {
        // Simulates rainfall utilizing block timestamp and block.prevrandao
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % 1000;
        return int256(randomFactor); // Returns a scaled response 0-999 (mm)
    }
}

// CropInsurance.sol
contract CropInsurance {
    AggregatorV3Interface public weatherOracle;
    address public owner;
    
    uint256 public constant RAINFALL_THRESHOLD = 300; // Expected rainfall threshold in mm
    uint256 public constant INSURANCE_PAYOUT = 0.5 ether;
    uint256 public constant PREMIUM = 0.05 ether;
    
    mapping(address => bool) public isInsured;
    
    // Instantiate with the oracle address
    constructor(address _oracle) payable {
        owner = msg.sender;
        weatherOracle = AggregatorV3Interface(_oracle);
    }
    
    function buyInsurance() external payable {
        require(msg.value == PREMIUM, "Must pay exact premium (0.05 ether)");
        require(!isInsured[msg.sender], "Already insured");
        isInsured[msg.sender] = true;
    }
    
    function checkRainfallAndClaim() external {
        require(isInsured[msg.sender], "Not insured");
        
        (
            /* uint80 roundID */,
            int256 rainfall,
            /* uint startedAt */,
            uint256 updatedAt,
            /* uint80 answeredInRound */
        ) = weatherOracle.latestRoundData();
        
        // Security check: Stale data
        // We ensure that the returned timestamp was within the last hour
        require(block.timestamp - updatedAt < 3600, "Stale data: oracle update exceeding limit");
        
        // Ensure rainfall is valid data
        require(rainfall >= 0, "Invalid rainfall data (negative value)");
        
        // Check condition: if rainfall drops below threshold, payout!
        if (uint256(rainfall) < RAINFALL_THRESHOLD) {
            
            // Re-entracny Guard Check: update state prior to transferring funds
            isInsured[msg.sender] = false; 
            
            require(address(this).balance >= INSURANCE_PAYOUT, "Insufficient pool balance to cover claim");
            (bool success, ) = msg.sender.call{value: INSURANCE_PAYOUT}("");
            require(success, "Payout transfer failed");
            
        } else {
            revert("Rainfall is above threshold, no payout");
        }
    }
    
    // Function allowing the owner or volunteers to fund the insurance pool
    function fundPool() external payable {}
}
