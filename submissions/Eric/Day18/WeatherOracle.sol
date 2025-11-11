//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title WheatherOracle
 * @author Eric (https://github.com/0xxEric)
 * @notice Demonstrates using an oracle (like Chainlink) to fetch off-chain weather data,farmers can claim insurance payout whe rainfall is less than threshold
 * @custom:project 30-days-of-solidity-submissions: Day20
 */

interface IWeatherOracle {
    /// @notice Request weather data for a specific location and season
    /// @dev Returns a request ID so we can identify the callback later
    function requestRainfallData(string calldata location) external returns (bytes32 requestId);

    /// @notice Called by external system (oracle node) to return rainfall data
    /// @dev The oracle will call back the consumer contract (this one)
    function fulfillRequest(bytes32 requestId, uint256 rainfall) external;
}

contract WeatherInsurance {
    // --- State variables ---
    address public owner;
    IWeatherOracle public weatherOracle;

    uint256 public rainfallThreshold; // minimum rainfall (mm) required
    uint256 public premium;           // insurance premium paid by farmer
    uint256 public payoutAmount;      // amount to pay if rainfall < threshold

    struct Policy {
        address farmer;
        string location;
        bool active;
        bool paidOut;
    }

    mapping(bytes32 => Policy) public policies;

    // --- Events ---
    event PolicyCreated(bytes32 requestId, address indexed farmer, string location);
    event OracleCallback(bytes32 requestId, uint256 rainfall);
    event InsurancePayout(address indexed farmer, uint256 amount);

    constructor(
        address oracleAddress,
        uint256 _threshold,
        uint256 _premium,
        uint256 _payout
    ) {
        owner = msg.sender;
        weatherOracle = IWeatherOracle(oracleAddress);
        rainfallThreshold = _threshold;
        premium = _premium;
        payoutAmount = _payout;
    }

    // --- Core Logic ---

    /// @notice Farmer buys insurance by paying premium and triggering data request
    function buyInsurance(string calldata location) external payable {
        require(msg.value == premium, "Incorrect premium amount");

        // Request rainfall data from oracle
        bytes32 requestId = weatherOracle.requestRainfallData(location);

        // Create policy record
        policies[requestId] = Policy({
            farmer: msg.sender,
            location: location,
            active: true,
            paidOut: false
        });

        emit PolicyCreated(requestId, msg.sender, location);
    }

    /// @notice Called by the oracle contract when rainfall data is ready
    /// @dev Only callable by the trusted oracle contract
    function fulfillWeatherData(bytes32 requestId, uint256 rainfall) external {
        require(msg.sender == address(weatherOracle), "Only oracle can fulfill");
        Policy storage policy = policies[requestId];
        require(policy.active, "Policy not active");

        emit OracleCallback(requestId, rainfall);

        // If rainfall below threshold => pay insurance
        if (rainfall < rainfallThreshold && !policy.paidOut) {
            policy.paidOut = true;
            policy.active = false;
            payable(policy.farmer).transfer(payoutAmount);
            emit InsurancePayout(policy.farmer, payoutAmount);
        } else {
            // Rainfall sufficient: insurance expires
            policy.active = false;
        }
    }

    /// @notice Withdraw accumulated premiums (only owner)
    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}
