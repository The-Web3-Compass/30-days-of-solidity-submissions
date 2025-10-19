// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SignThis {
    address public organizer;
    mapping(address => bool) public hasEntered;

    constructor(address _organizer) {
        organizer = _organizer;
    }

    function enterEvent(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 messageHash = prefixed(keccak256(abi.encodePacked(message, msg.sender)));
        address signer = ecrecover(messageHash, v, r, s);
        require(signer == organizer, "Invalid signature");
        require(!hasEntered[msg.sender], "Already entered");
        hasEntered[msg.sender] = true;
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
