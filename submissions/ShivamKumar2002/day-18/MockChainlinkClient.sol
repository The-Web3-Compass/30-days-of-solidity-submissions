// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Chainlink Library (Mock)
 * @author shivam
 * @notice Defines a simplified Chainlink Request structure for the mock environment.
 * @dev A real Chainlink.Request is more complex, but this is sufficient for simulation purposes.
 */
library Chainlink {
    /// @notice Represents a simplified Chainlink request.
    /// @dev Note: this is a simplified version of the real Chainlink.Request struct.
    /// @dev See the Chainlink documentation for a detailed description of the real struct.
    struct Request {
        /// @notice The ID of the request.
        bytes32 id;
        /// @notice The address of the contract to call when the request is fulfilled.
        address callbackAddress;
        /// @notice The function selector of the callback function to call.
        bytes4 callbackFunctionId;
        /// @notice Nonce associated with the request.
        uint256 nonce;
        /// @notice Additional data associated with the request.
        bytes data;
    }
    /**
     * @notice Builds a simplified Chainlink request object for the mock environment.
     * @param _jobId The ID of the job to be executed (conceptual for mock).
     * @param _callbackAddress The address of the contract to call when the request is fulfilled.
     * @param _callbackFunctionId The function selector of the callback function to call.
     * @return request Chainlink.Request object with the given parameters.
     */
    function buildChainlinkRequest(bytes32 _jobId, address _callbackAddress, bytes4 _callbackFunctionId) internal pure returns (Request memory) {
        // Silence unused variable warnings (conceptual parameters)
        _jobId;
        
        // _jobId is part of the data in a real request, not the struct itself.
        return Request({
            id: bytes32(0),
            callbackAddress: _callbackAddress,
            callbackFunctionId: _callbackFunctionId,
            nonce: 0,
            data: ""
        });
    }
}


/**
 * @title MockChainlinkClient
 * @author shivam
 * @notice A base contract that simulates the Chainlink client functionality for local testing (e.g., in Remix).
 * @dev Allows manual triggering of the `fulfill` callback.
 * @dev DO NOT USE THIS ON A LIVE NETWORK. This is for simulation only.
 */
contract MockChainlinkClient {
    /// @notice Tracks active request IDs for simulation purposes.
    /// @dev In a real ChainlinkClient, this maps request IDs to pending callbacks.
    mapping(bytes32 => bool) public activeRequests; // Made public for easier inspection

    /// @notice Simple counter to help generate unique mock request IDs.
    uint256 private requestCount = 0;

    /// @notice Stores the mock LINK token address.
    /// @dev Set via `setChainlinkToken`.
    address private mockLinkTokenAddress;

    /// @notice Emitted when a request is marked as fulfilled (or attempted).
    event ChainlinkCallbackRecorded(bytes32 indexed requestId);

    /// @notice Initializes the mock client.
    constructor() {}

    // --- Mock Chainlink Base Functions ---

    /// @notice Simulates setting the LINK token address for the client.
    /// @param _link The address of the (mock) LINK token contract.
    /// @dev In a real client, this stores the address for LINK transfers. In the mock, it just stores it.
    function setChainlinkToken(address _link) internal {
        mockLinkTokenAddress = _link;
    }

    /**
     * @notice Simulates building a Chainlink request structure using the mock library.
     * @param _jobId The Job ID (conceptual for mock).
     * @param _callbackAddress The address of the contract to call back.
     * @param _callbackFunctionId The function selector of the callback function.
     * @return req The simulated Chainlink request object.
     */
    function buildChainlinkRequest(bytes32 _jobId, address _callbackAddress, bytes4 _callbackFunctionId) internal pure returns (Chainlink.Request memory req) {
        return Chainlink.buildChainlinkRequest(_jobId, _callbackAddress, _callbackFunctionId);
    }

    /**
     * @notice Simulates sending a Chainlink request to an oracle.
     * @param _oracle The address of the oracle contract (conceptual for mock).
     * @param _request The simulated request object.
     * @param _fee The amount of LINK fee (conceptual for mock).
     * @return requestId The simulated request ID.
     * @dev In the mock, this generates a unique request ID and marks it as active.
     * @dev It does NOT interact with a real oracle or transfer LINK tokens.
     * @dev The request ID generation is simplified for the mock environment.
     */
    function sendChainlinkRequestTo(address _oracle, Chainlink.Request memory _request, uint256 _fee) internal returns (bytes32 requestId) {
        // Generate a unique (for this mock) request ID
        // In reality, the oracle node generates the ID upon receiving the request.
        requestCount++;
        requestId = keccak256(abi.encodePacked(address(this), requestCount, block.timestamp, block.prevrandao));

        // Mark this ID as active, expecting a fulfill call
        activeRequests[requestId] = true;

        // Silence unused variable warnings (conceptual parameters)
        _oracle;
        _request;
        _fee;
        
        return requestId;
    }

    /**
     * @notice This is the base callback function that a Chainlink node would call.
     * @param _requestId The ID of the request being fulfilled.
     * @param _data The raw data returned by the oracle.
     * @dev In this MOCK contract, it is made `public` and `virtual` so it can be called manually
     *      for testing purposes (e.g., in Remix) and overridden by the consumer contract.
     * @dev The consumer contract is responsible for decoding the `_data` parameter.
     * @dev In a real ChainlinkClient, this function would have modifiers (like `recordChainlinkCallback`)
     *      to validate the caller (oracle) and the `_requestId`. These are omitted in the mock.
     * @dev This base implementation marks the request as inactive.
     */
    function fulfill(bytes32 _requestId, bytes memory _data) public virtual {
        // Check if the request ID is valid/active before proceeding
        // In a real scenario, modifiers handle this. Here, we do a basic check.
        require(activeRequests[_requestId], "Request ID not found or already fulfilled");

        // Mark the request as fulfilled (inactive)
        delete activeRequests[_requestId];

        // Emit an event indicating the callback was recorded
        emit ChainlinkCallbackRecorded(_requestId);

        // Silence unused parameter warning for _data in the base implementation, the consumer contract will use this parameter.
        _data;
    }
}