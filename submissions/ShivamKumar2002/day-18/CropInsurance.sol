// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import mock client
import "./MockChainlinkClient.sol";

/**
 * @title CropInsurance (Using Mocked Oracle)
 * @author shivam
 * @notice A decentralized crop insurance contract using a simulated Chainlink oracle for rainfall data.
 * @dev Inherits from `MockChainlinkClient` to enable manual data fulfillment for local testing.
 * @dev Farmers can register, deposit collateral, and claim insurance if rainfall is below a threshold.
 */
contract CropInsurance is MockChainlinkClient {
    /// @notice Insurance policy state
    struct Policy {
        /// @notice Farmer address
        address farmer;
        /// @notice Amount deposited by farmer as collateral/premium
        uint256 insuredAmount;
        /// @notice Minimum rainfall required (e.g., in mm)
        uint256 rainfallThreshold;
        /// @notice Location for which rainfall data is relevant
        string location;
        /// @notice Is the policy currently active?
        bool isActive;
        /// @notice Has the insurance payout been made?
        bool payoutMade;
        /// @notice The ID of the last rainfall data request for this policy
        bytes32 lastRequestId;
    }

    /// @notice Mapping from farmer address to their policy details
    mapping(address => Policy) public policies;

    /// @notice Mapping from request ID to farmer address for efficient lookup in fulfill
    mapping(bytes32 => address) public requestToFarmer;

    /// @notice Oracle address
    address private immutable oracle;
    /// @notice Job ID for rainfall data
    bytes32 private immutable jobId;
    /// @notice LINK fee
    uint256 private immutable fee;

    // --- Events ---
    /// @notice Emitted when a farmer registers a new policy
    /// @param farmer The address of the farmer
    /// @param insuredAmount The amount deposited by the farmer as collateral/premium
    /// @param rainfallThreshold The minimum rainfall required (e.g., in mm)
    /// @param location The location for which rainfall data is relevant
    event PolicyRegistered(address indexed farmer, uint256 insuredAmount, uint256 rainfallThreshold, string location);

    /// @notice Emitted when a rainfall data request is initiated
    /// @param requestId The ID of the initiated request
    /// @param farmer The address of the farmer
    /// @param location The location for which rainfall data is requested
    event RainfallDataRequested(bytes32 indexed requestId, address indexed farmer, string location);

    /// @notice Emitted when rainfall data is received
    /// @param requestId The ID of the request
    /// @param farmer The address of the farmer
    /// @param location The location for which rainfall data is requested
    /// @param rainfall The rainfall amount received
    event RainfallDataReceived(bytes32 indexed requestId, address indexed farmer, string location, uint256 rainfall);

    /// @notice Emitted when insurance payout is made
    /// @param farmer The address of the farmer
    /// @param amount The amount of ETH payout
    /// @param rainfallReceived The amount of rainfall received
    event InsurancePayout(address indexed farmer, uint256 amount, uint256 rainfallReceived);
    
    /// @notice Emitted when insurance period ends
    /// @param farmer The address of the farmer
    /// @param rainfallReceived The amount of rainfall received
    event InsurancePeriodEnded(address indexed farmer, uint256 rainfallReceived);
    
    /// @notice Emitted when insurance payout fails
    /// @param farmer The address of the farmer
    /// @param amount The amount of ETH payout
    event PayoutFailed(address indexed farmer, uint256 amount);

    // --- Constructor ---
    /**
     * @notice Initializes the contract with Chainlink oracle parameters (mocked).
     * @param _link The address of the (mock) LINK token contract.
     * @param _oracle The address of the (mock) Chainlink oracle node contract.
     * @param _jobId The Job ID for the rainfall data request (conceptual for mock).
     * @param _fee The LINK token fee amount (conceptual for mock).
     */
    constructor(address _link, address _oracle, bytes32 _jobId, uint256 _fee) MockChainlinkClient() {
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
        setChainlinkToken(_link); // Use the mock setter
    }

    // --- Policy Management ---
    /**
     * @notice Allows a farmer to register an insurance policy by depositing collateral.
     * @param _rainfallThreshold The minimum rainfall (e.g., in mm) below which insurance pays out.
     * @param _location The location (e.g., city, region) for the rainfall data request.
     * @dev Farmer sends ETH along with the call as the insured amount.
     * @dev Only one active policy per farmer is allowed in this simple version.
     */
    function registerPolicy(uint256 _rainfallThreshold, string memory _location) public payable {
        require(msg.value > 0, "Insured amount must be greater than zero");
        // Check if farmer exists in mapping first to avoid redundant storage read if new
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

    // --- Request Function ---
    /**
     * @notice Requests the rainfall data for the farmer's registered location.
     * @return reqId The ID of the initiated simulated request.
     * @dev Only callable by a farmer with an active, unpaid policy.
     * @dev Triggers the mock Chainlink oracle request.
     */
    function requestRainfallData() public returns (bytes32 reqId) {
        Policy storage policy = policies[msg.sender];
        require(policy.isActive, "No active policy found for this farmer");
        require(!policy.payoutMade, "Payout already made or policy concluded");
        // Prevent overlapping requests per policy
        require(policy.lastRequestId == bytes32(0), "Previous request still pending");

        // Build the simulated Chainlink request
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Simulate sending the request
        reqId = sendChainlinkRequestTo(oracle, request, fee);

        // Store the request ID against the policy and in the lookup mapping
        policy.lastRequestId = reqId;
        // Map request ID to farmer
        requestToFarmer[reqId] = msg.sender;

        emit RainfallDataRequested(reqId, msg.sender, policy.location);
        return reqId;
    }

    // --- Callback Function ---
    /**
     * @notice Callback function called by the simulated oracle to deliver the requested rainfall data.
     * @param _requestId The ID of the request this callback corresponds to.
     * @param _data The raw bytes data returned by the oracle, expected to be abi.encode(uint256) representing rainfall.
     * @dev Overrides `MockChainlinkClient.fulfill`.
     * @dev Decodes rainfall, checks against threshold, and triggers payout if necessary.
     * @dev Uses `requestToFarmer` mapping for efficient lookup.
     */
    function fulfill(bytes32 _requestId, bytes memory _data) public override {
        // Call the base implementation first to handle request ID validation and cleanup in activeRequests mapping
        super.fulfill(_requestId, _data); // This will revert if _requestId is not active

        // Find the farmer associated with this request ID using the mapping
        address farmerAddress = requestToFarmer[_requestId];
        require(farmerAddress != address(0), "Farmer not found for this request ID"); // Ensure mapping exists

        Policy storage policy = policies[farmerAddress];
        // Additional check: ensure the request ID matches the one stored in the policy
        require(policy.lastRequestId == _requestId, "Request ID mismatch in policy");
        require(policy.isActive, "Policy is not active"); // Should be active if request was made
        require(!policy.payoutMade, "Payout already processed for this policy");

        // Decode the rainfall data (assuming uint256 for rainfall in mm)
        uint256 rainfall = abi.decode(_data, (uint256));

        emit RainfallDataReceived(_requestId, farmerAddress, policy.location, rainfall);

        // Check insurance condition
        if (rainfall < policy.rainfallThreshold) {
            // Rainfall below threshold - Payout insurance
            policy.payoutMade = true;
            // Policy concludes after payout
            policy.isActive = false;
            uint256 payoutAmount = policy.insuredAmount;
            // Zero out amount before transfer for security
            policy.insuredAmount = 0;

            // Clear request ID mapping before potential reentrancy via transfer
            delete requestToFarmer[_requestId];
            policy.lastRequestId = bytes32(0);

            // Attempt ETH transfer
            (bool success, ) = payable(policy.farmer).call{value: payoutAmount}("");
            if (success) {
                emit InsurancePayout(farmerAddress, payoutAmount, rainfall);
            } else {
                // Payout failed - farmer needs to withdraw manually.
                // Reset flags and restore amount for withdrawal.
                policy.payoutMade = false;
                policy.isActive = false; // Keep inactive, but allow withdrawal
                policy.insuredAmount = payoutAmount; // Restore amount for withdrawal
                emit PayoutFailed(farmerAddress, payoutAmount);
            }
            
        } else {
            // Rainfall met or exceeded threshold - No payout, policy concludes, return collateral
            policy.isActive = false; // Policy period ends
            uint256 returnAmount = policy.insuredAmount;
            policy.insuredAmount = 0; // Zero out amount before transfer

             // Clear request ID mapping
            delete requestToFarmer[_requestId];
            policy.lastRequestId = bytes32(0); // Clear from policy

            // Attempt to return the collateral
            (bool success, ) = payable(policy.farmer).call{value: returnAmount}("");
            if (success) {
                 emit InsurancePeriodEnded(farmerAddress, rainfall);
            } else {
                // Return failed. Farmer needs to withdraw manually.
                policy.isActive = false; // Keep inactive
                policy.insuredAmount = returnAmount; // Restore amount for withdrawal
                emit PayoutFailed(farmerAddress, returnAmount); // Re-use PayoutFailed event
            }
        }
    }

    // --- Getter Functions ---

    function getPolicyDetails(address _farmer) public view returns (Policy memory) {
        require(policies[_farmer].farmer != address(0), "No policy found for this farmer");
        return policies[_farmer];
    }

    function isPolicyActive(address _farmer) public view returns (bool) {
        require(policies[_farmer].farmer != address(0), "No policy found for this farmer");
        return policies[_farmer].isActive;
    }

    // --- Fallback and Receive ---
    /// @notice Allows the contract to receive ETH.
    /// @dev Required for receiving collateral from farmers.
    receive() external payable {}
    fallback() external payable {}

    // --- Optional: Withdrawal function for failed transfers ---
    /// @notice Allows a farmer to withdraw their insured amount if automatic payout/return failed.
    /// @dev Only callable if policy is inactive AND payout was not successfully made/returned
    ///     and there's a balance remaining associated with the policy.
    function withdrawFunds() public {
        Policy storage policy = policies[msg.sender];
        require(policy.farmer == msg.sender, "Caller is not the policyholder"); // Ensure caller owns the policy
        require(!policy.isActive, "Policy is still active");
        // Check if payout/return was attempted but failed (indicated by insuredAmount > 0 when inactive)
        require(policy.insuredAmount > 0, "No funds to withdraw or payout/return already successful");

        uint256 amountToWithdraw = policy.insuredAmount;
        policy.insuredAmount = 0; // Prevent re-entrancy and double withdrawal

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Withdrawal transfer failed");
        // Optionally emit a Withdrawal event
    }


    // --- Simulation Note ---
    // To simulate in Remix:
    // 1. Deploy CropInsurance (provide dummy addresses/bytes32 for constructor).
    // 2. Call `registerPolicy` from Farmer A, sending 1 ETH, threshold 20, location "Farm A".
    // 3. Call `requestRainfallData` from Farmer A. Note the `requestId`.
    // 4. Manually call `fulfill` on CropInsurance. Provide Farmer A's `requestId` and mock `_data`.
    //    - Scenario 1 (Payout): Encode rainfall 15 (`uint256(15)`). Check Farmer A balance increases (less gas). Policy becomes inactive. Check `insuredAmount` is 0 via `getPolicyDetails`.
    //    - Scenario 2 (No Payout): Encode rainfall 25 (`uint256(25)`). Check Farmer A balance increases by original 1 ETH (less gas). Policy becomes inactive. Check `insuredAmount` is 0 via `getPolicyDetails`.
    // 5. Check policy status using `getPolicyDetails`. Observe events.
    // 6. (Optional Failure Simulation): Modify `fulfill` temporarily to force payout/return failure, then call `withdrawFunds`.
}