// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract CropInsurance is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;
    
    // Insurance policy structure
    struct Policy {
        address farmer;
        uint256 premium;
        uint256 coverageAmount;
        uint256 startDate;
        uint256 endDate;
        int256 rainfallThreshold; // in mm
        string location;
        bool claimed;
    }

    // Chainlink configuration
    address private oracleAddress;
    bytes32 private jobId;
    uint256 private fee;
    
    // Mappings
    mapping(bytes32 => uint256) public requestIdToPolicyId;
    mapping(uint256 => Policy) public policies;
    uint256 public policyCount;
    
    // Events
    event PolicyCreated(
        uint256 indexed policyId,
        address indexed farmer,
        uint256 premium,
        uint256 coverageAmount
    );
    event RainfallRequested(
        uint256 indexed policyId,
        bytes32 indexed requestId
    );
    event ClaimProcessed(
        uint256 indexed policyId,
        address indexed farmer,
        uint256 payoutAmount,
        int256 actualRainfall
    );

    constructor(
        address _linkToken,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) ConfirmedOwner(msg.sender) {
        setChainlinkToken(_linkToken);
        oracleAddress = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    /**
     * @dev Purchase insurance policy
     * @param _premium Insurance premium paid by farmer
     * @param _coverageAmount Payout amount if claim is valid
     * @param _startDate Start of coverage period (UNIX timestamp)
     * @param _endDate End of coverage period (UNIX timestamp)
     * @param _rainfallThreshold Minimum rainfall required (mm)
     * @param _location Location coordinates (e.g., "52.52,13.41")
     */
    function purchasePolicy(
        uint256 _premium,
        uint256 _coverageAmount,
        uint256 _startDate,
        uint256 _endDate,
        int256 _rainfallThreshold,
        string memory _location
    ) external payable {
        require(msg.value >= _premium, "Insufficient premium");
        require(_endDate > _startDate, "Invalid date range");
        require(_rainfallThreshold > 0, "Invalid threshold");
        
        policyCount++;
        policies[policyCount] = Policy({
            farmer: msg.sender,
            premium: _premium,
            coverageAmount: _coverageAmount,
            startDate: _startDate,
            endDate: _endDate,
            rainfallThreshold: _rainfallThreshold,
            location: _location,
            claimed: false
        });
        
        emit PolicyCreated(policyCount, msg.sender, _premium, _coverageAmount);
    }

    /**
     * @dev Initiate claim process by requesting rainfall data
     * @param _policyId ID of the insurance policy
     */
    function requestClaim(uint256 _policyId) external {
        Policy storage policy = policies[_policyId];
        require(policy.farmer == msg.sender, "Not policy owner");
        require(block.timestamp > policy.endDate, "Coverage period not ended");
        require(!policy.claimed, "Claim already processed");
        
        // Build Chainlink request
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillClaim.selector
        );
        
        // Set parameters for weather API request
        req.add("lat", splitLocation(policy.location, 0)); // Extract latitude
        req.add("lon", splitLocation(policy.location, 1)); // Extract longitude
        req.add("start", uintToString(policy.startDate));
        req.add("end", uintToString(policy.endDate));
        
        // Request total rainfall in millimeters
        req.add("path", "total_precipitation_sum");
        
        // Send request
        bytes32 requestId = sendChainlinkRequestTo(oracleAddress, req, fee);
        requestIdToPolicyId[requestId] = _policyId;
        
        emit RainfallRequested(_policyId, requestId);
    }

    /**
     * @dev Callback function for Chainlink oracle response
     * @param _requestId The request ID from Chainlink
     * @param _rainfall Total rainfall in millimeters (multiplied by 100)
     */
    function fulfillClaim(bytes32 _requestId, bytes32 _rainfall) 
        external 
        recordChainlinkFulfillment(_requestId)
    {
        uint256 policyId = requestIdToPolicyId[_requestId];
        Policy storage policy = policies[policyId];
        
        require(!policy.claimed, "Claim already processed");
        policy.claimed = true;
        
        // Convert rainfall to int (API returns value * 100)
        int256 actualRainfall = int256(uint256(_rainfall)) / 100;
        
        // Process payout if below threshold
        if (actualRainfall < policy.rainfallThreshold) {
            uint256 payoutAmount = policy.coverageAmount;
            payable(policy.farmer).transfer(payoutAmount);
            emit ClaimProcessed(policyId, policy.farmer, payoutAmount, actualRainfall);
        } else {
            emit ClaimProcessed(policyId, policy.farmer, 0, actualRainfall);
        }
    }

    // Helper functions
    function splitLocation(string memory _location, uint256 _index) 
        private 
        pure 
        returns (string memory) 
    {
        strings.slice memory s = _location.toSlice();
        strings.slice memory delim = ",".toSlice();
        string[] memory parts = new string[](2);
        parts[0] = s.split(delim).toString();
        parts[1] = s.toString();
        return parts[_index];
    }

    function uintToString(uint256 _value) private pure returns (string memory) {
        if (_value == 0) return "0";
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    // Management functions
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function updateOracleSettings(
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) external onlyOwner {
        oracleAddress = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    // Receive ETH for premium payments
    receive() external payable {}
}