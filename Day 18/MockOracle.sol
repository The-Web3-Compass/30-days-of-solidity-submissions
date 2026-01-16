// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockOracle {
    address public lastRequester;
    bytes public lastPayload;

    function requestData(address requester, bytes calldata payload) external returns (bytes32) {
        lastRequester = requester;
        lastPayload = payload;
        return keccak256(abi.encodePacked(block.timestamp, requester, payload));
    }

    function fulfillRequest(address requester, bytes32 requestId, uint256 rainfallMm) external {
        (bool ok, ) = requester.call(
            abi.encodeWithSignature("fulfill(bytes32,uint256)", requestId, rainfallMm)
        );
        require(ok, "fulfill failed");
    }
}
