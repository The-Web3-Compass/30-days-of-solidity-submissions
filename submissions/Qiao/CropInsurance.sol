// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable {
    AggregatorV3Interface private oracleRainfall;
    mapping(address => uint256) public lastClaimTimestamp;
    mapping(address => bool) isInsured;
    uint256 premium;
    uint256 payout;
    uint256 thresholdRainfall;

    constructor (address _oracleRainfall, uint256 _premium, uint256 _payout, uint256 _thresholdRainfall) 
    payable Ownable(msg.sender) {
        oracleRainfall = AggregatorV3Interface(_oracleRainfall);
        premium = _premium;
        payout = _payout;
        thresholdRainfall = _thresholdRainfall;
    }

    event InsurancePurchased(address indexed farmer, uint256 amount);
    event ClaimSubmitted(address indexed farmer);
    event ClaimPaid(address indexed farmer, uint256 amount);
    event RainfallChecked(address indexed farmer, uint256 rainfall);

    function payPremium () external payable {
        // pay action
        require(msg.value >= premium, "Invalid payment amount.");
        require(!isInsured[msg.sender], "Already insured.");

        isInsured[msg.sender] == true;
        emit InsurancePurchased(msg.sender, msg.value);
    } 

    function claim() external {
        require(isInsured[msg.sender], "No valid insurance policy.");
        require(block.timestamp >= lastClaimTimestamp[msg.sender] + 1 days, "Must wait 24h between claims");

        (uint80 roundId, int256 rainfall, , uint256 updatedAt, uint80 answeredInRound) = 
            oracleRainfall.latestRoundData();
        require(updatedAt > 0, "Round not complete");
        require(answeredInRound >= roundId, "Stale data");

        emit RainfallChecked(msg.sender, uint256(rainfall));

        if (uint256(rainfall) < thresholdRainfall) {
            lastClaimTimestamp[msg.sender] = block.timestamp;
            emit ClaimSubmitted(msg.sender);

            (bool success, ) = msg.sender.call{value: payout}("");
            require(success, "Payout failed");

            emit ClaimPaid(msg.sender, payout);
        }

    }

    function getCurrentRainfall() public view returns (uint256) {
        (
            ,
            int256 rainfall,
            ,
            ,
        ) = oracleRainfall.latestRoundData();

        return uint256(rainfall);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}


   
