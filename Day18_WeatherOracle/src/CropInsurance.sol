// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IWeatherConsumer {
    function getStoredRainfall() external view returns (int256);
}

contract CropInsurance {
    address public owner;
    IWeatherConsumer public weatherConsumer;

    struct Policy {
        address farmer;
        uint256 premium;
        uint256 insuredAmount;
        int256 rainfallThreshold;
        uint256 startTime;
        uint256 endTime;
        bool paidOut;
    }

    mapping(uint256 => Policy) public policies;
    uint256 public policyCount;

    event PolicyCreated(uint256 policyId, address farmer, uint256 insuredAmount, int256 threshold);
    event PolicyPaid(uint256 policyId, address farmer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _consumer) {
        owner = msg.sender;
        weatherConsumer = IWeatherConsumer(_consumer);
    }

    receive() external payable {}

    function buyPolicy(uint256 insuredAmount, int256 rainfallThreshold, uint256 duration) external payable {
        require(msg.value > 0, "Premium required");

        policyCount++;
        policies[policyCount] = Policy({
            farmer: msg.sender,
            premium: msg.value,
            insuredAmount: insuredAmount,
            rainfallThreshold: rainfallThreshold,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            paidOut: false
        });

        emit PolicyCreated(policyCount, msg.sender, insuredAmount, rainfallThreshold);
    }

    function evaluatePolicy(uint256 policyId) external {
        Policy storage p = policies[policyId];
        require(!p.paidOut, "Already paid");
        require(block.timestamp >= p.endTime, "Policy still active");

        int256 rainfall = weatherConsumer.getStoredRainfall();
        if (rainfall < p.rainfallThreshold) {
            p.paidOut = true;
            payable(p.farmer).transfer(p.insuredAmount);
            emit PolicyPaid(policyId, p.farmer, p.insuredAmount);
        }
    }

    function fundContract() external payable onlyOwner {}
}
