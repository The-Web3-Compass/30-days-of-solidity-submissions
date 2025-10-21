// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockChainlinkClient.sol";

contract CropInsurance is MockChainlinkClient {
    struct Policy {
        address farmer;             // Farmer address
        uint256 insuredAmount;      // Collateral/premium
        uint256 rainfallThreshold;  // Threshold in mm
        string location;            // Location for rainfall
        bool isActive;              // Is policy active
        bool payoutMade;            // Was payout made
        bytes32 lastRequestId;      // Last request ID
    }

    mapping(address => Policy) public policies;          // Farmer -> Policy
    mapping(bytes32 => address) public requestToFarmer; // Request -> Farmer

    address private immutable oracle; // Oracle address
    bytes32 private immutable jobId;  // Job ID
    uint256 private immutable fee;    // LINK fee

    event PolicyRegistered(address indexed farmer, uint256 insuredAmount, uint256 rainfallThreshold, string location);
    event RainfallDataRequested(bytes32 indexed requestId, address indexed farmer, string location);
    event RainfallDataReceived(bytes32 indexed requestId, address indexed farmer, string location, uint256 rainfall);
    event InsurancePayout(address indexed farmer, uint256 amount, uint256 rainfallReceived);
    event InsurancePeriodEnded(address indexed farmer, uint256 rainfallReceived);
    event PayoutFailed(address indexed farmer, uint256 amount);

    constructor(address _link, address _oracle, bytes32 _jobId, uint256 _fee) MockChainlinkClient() {
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
        setChainlinkToken(_link);
    }

    function registerPolicy(uint256 _rainfallThreshold, string memory _location) public payable {
        require(msg.value > 0, "Insured amount must be greater than zero");
        Policy storage existingPolicy = policies[msg.sender];
        require(!existingPolicy.isActive, "Farmer already has an active policy");
        require(_rainfallThreshold > 0, "Rainfall threshold must be positive");
        require(bytes(_location).length > 0, "Location cannot be empty");

        policies[msg.sender] = Policy({
            farmer: msg.sender,
            insuredAmount: msg.value,
            rainfallThreshold: _rainfallThreshold,
            location: _location,
            isActive: true,
            payoutMade: false,
            lastRequestId: bytes32(0)
        });

        emit PolicyRegistered(msg.sender, msg.value, _rainfallThreshold, _location);
    }

    function requestRainfallData() public returns (bytes32 reqId) {
        Policy storage policy = policies[msg.sender];
        require(policy.isActive, "No active policy found for this farmer");
        require(!policy.payoutMade, "Payout already made or policy concluded");
        require(policy.lastRequestId == bytes32(0), "Previous request still pending");

        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        reqId = sendChainlinkRequestTo(oracle, request, fee);
        policy.lastRequestId = reqId;
        requestToFarmer[reqId] = msg.sender;

        emit RainfallDataRequested(reqId, msg.sender, policy.location);
        return reqId;
    }

    function fulfill(bytes32 _requestId, bytes memory _data) public override {
        super.fulfill(_requestId, _data);

        address farmerAddress = requestToFarmer[_requestId];
        require(farmerAddress != address(0), "Farmer not found for this request ID");

        Policy storage policy = policies[farmerAddress];
        require(policy.lastRequestId == _requestId, "Request ID mismatch in policy");
        require(policy.isActive, "Policy is not active");
        require(!policy.payoutMade, "Payout already processed");

        uint256 rainfall = abi.decode(_data, (uint256));
        emit RainfallDataReceived(_requestId, farmerAddress, policy.location, rainfall);

        if (rainfall < policy.rainfallThreshold) {
            policy.payoutMade = true;
            policy.isActive = false;
            uint256 payoutAmount = policy.insuredAmount;
            policy.insuredAmount = 0;
            delete requestToFarmer[_requestId];
            policy.lastRequestId = bytes32(0);

            (bool success, ) = payable(policy.farmer).call{value: payoutAmount}("");
            if (success) {
                emit InsurancePayout(farmerAddress, payoutAmount, rainfall);
            } else {
                policy.payoutMade = false;
                policy.isActive = false;
                policy.insuredAmount = payoutAmount;
                emit PayoutFailed(farmerAddress, payoutAmount);
            }
        } else {
            policy.isActive = false;
            uint256 returnAmount = policy.insuredAmount;
            policy.insuredAmount = 0;
            delete requestToFarmer[_requestId];
            policy.lastRequestId = bytes32(0);

            (bool success, ) = payable(policy.farmer).call{value: returnAmount}("");
            if (success) {
                emit InsurancePeriodEnded(farmerAddress, rainfall);
            } else {
                policy.isActive = false;
                policy.insuredAmount = returnAmount;
                emit PayoutFailed(farmerAddress, returnAmount);
            }
        }
    }

    function getPolicyDetails(address _farmer) public view returns (Policy memory) {
        require(policies[_farmer].farmer != address(0), "No policy found for this farmer");
        return policies[_farmer];
    }

    function isPolicyActive(address _farmer) public view returns (bool) {
        require(policies[_farmer].farmer != address(0), "No policy found for this farmer");
        return policies[_farmer].isActive;
    }

    receive() external payable {} // Accept ETH
    fallback() external payable {} // Fallback for ETH

    function withdrawFunds() public {
        Policy storage policy = policies[msg.sender];
        require(policy.farmer == msg.sender, "Caller is not the policyholder");
        require(!policy.isActive, "Policy is still active");
        require(policy.insuredAmount > 0, "No funds to withdraw");

        uint256 amountToWithdraw = policy.insuredAmount;
        policy.insuredAmount = 0;

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Withdrawal transfer failed");
    }
}
