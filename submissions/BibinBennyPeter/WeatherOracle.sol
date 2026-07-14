// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract CropInsurance is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    address public owner;
    uint256 public rainfallThreshold;
    uint256 public premiumCost;
    uint256 public payoutAmount;
    uint256 public coverageEndTime;
    bool public outcomeAvailable;
    mapping(address => bool) public insured;
    mapping(address => bool) public hasClaimed;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    mapping(bytes32 => bool) private pendingRequests;
    uint256 public latestRainfall;

    event InsurancePurchased(address indexed farmer);
    event RainfallRequested(bytes32 indexed requestId);
    event RainfallUpdated(uint256 rainfall);
    event PayoutClaimed(address indexed farmer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        uint256 _durationSeconds,
        uint256 _rainfallThreshold,
        uint256 _premiumCost,
        uint256 _payoutAmount,
        address _linkToken,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) {
        owner = msg.sender;
        coverageEndTime = block.timestamp + _durationSeconds;
        rainfallThreshold = _rainfallThreshold;
        premiumCost = _premiumCost;
        payoutAmount = _payoutAmount;
        setChainlinkToken(_linkToken);
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    function buyInsurance() external payable {
        require(block.timestamp < coverageEndTime, "Season ended");
        require(msg.value == premiumCost, "Incorrect premium amount");
        require(!insured[msg.sender], "Already insured");
        insured[msg.sender] = true;
        emit InsurancePurchased(msg.sender);
    }

    function requestWeatherData(string memory url, string memory path) external onlyOwner returns (bytes32 requestId) {
        require(block.timestamp >= coverageEndTime, "Too early");
        require(!outcomeAvailable, "Already fetched");
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("get", url);
        req.add("path", path);
        requestId = sendChainlinkRequestTo(oracle, req, fee);
        pendingRequests[requestId] = true;
        emit RainfallRequested(requestId);
    }

    function fulfill(bytes32 _requestId, uint256 _rainfall) public recordChainlinkFulfillment(_requestId) {
        require(pendingRequests[_requestId], "Unrecognized request");
        latestRainfall = _rainfall;
        outcomeAvailable = true;
        delete pendingRequests[_requestId];
        emit RainfallUpdated(_rainfall);
    }

    function claimInsurance() external {
        require(insured[msg.sender], "Not insured");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(outcomeAvailable, "Outcome not available");
        require(latestRainfall < rainfallThreshold, "No payout");
        require(address(this).balance >= payoutAmount, "Insufficient balance");
        hasClaimed[msg.sender] = true;
        payable(msg.sender).transfer(payoutAmount);
        emit PayoutClaimed(msg.sender, payoutAmount);
    }

    function fundContract() external payable onlyOwner {}

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
