// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Chainlink {
    struct Request {
        bytes32 id;                // Request ID
        address callbackAddress;   // Callback contract address
        bytes4 callbackFunctionId; // Callback function selector
        uint256 nonce;             // Request nonce
        bytes data;                // Additional request data
    }

    function buildChainlinkRequest(bytes32 _jobId, address _callbackAddress, bytes4 _callbackFunctionId) internal pure returns (Request memory) {
        _jobId; // Unused in mock
        return Request({
            id: bytes32(0),
            callbackAddress: _callbackAddress,
            callbackFunctionId: _callbackFunctionId,
            nonce: 0,
            data: ""
        });
    }
}

contract MockChainlinkClient {
    mapping(bytes32 => bool) public activeRequests; // Tracks active requests
    uint256 private requestCount = 0;               // Counter for generating request IDs
    address private mockLinkTokenAddress;           // Mock LINK token address

    event ChainlinkCallbackRecorded(bytes32 indexed requestId); // Event for callback

    constructor() {}

    function setChainlinkToken(address _link) internal {
        mockLinkTokenAddress = _link; // Store LINK token address
    }

    function buildChainlinkRequest(bytes32 _jobId, address _callbackAddress, bytes4 _callbackFunctionId) internal pure returns (Chainlink.Request memory req) {
        return Chainlink.buildChainlinkRequest(_jobId, _callbackAddress, _callbackFunctionId);
    }

    function sendChainlinkRequestTo(address _oracle, Chainlink.Request memory _request, uint256 _fee) internal returns (bytes32 requestId) {
        requestCount++;
        requestId = keccak256(abi.encodePacked(address(this), requestCount, block.timestamp, block.prevrandao));
        activeRequests[requestId] = true;
        _oracle; _request; _fee; // Unused in mock
        return requestId;
    }

    function fulfill(bytes32 _requestId, bytes memory _data) public virtual {
        require(activeRequests[_requestId], "Request ID not found or already fulfilled");
        delete activeRequests[_requestId];
        emit ChainlinkCallbackRecorded(_requestId);
        _data; // Unused in base
    }
}
