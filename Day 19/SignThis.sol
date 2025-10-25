// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignThis {
    address public organizer;
    mapping(address => bool) public hasEntered;

    event AccessGranted(address indexed attendee);

    constructor() {
        organizer = msg.sender;
    }

    // Verify signature and grant access
    function enterEvent(bytes32 messageHash, bytes memory signature) external {
        require(!hasEntered[msg.sender], "Already entered");

        address signer = recoverSigner(messageHash, signature);
        require(signer == organizer, "Invalid signature");

        hasEntered[msg.sender] = true;
        emit AccessGranted(msg.sender);
    }

    // Recover signer address from signature
    function recoverSigner(bytes32 _hash, bytes memory _sig) public pure returns (address) {
        require(_sig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        // Ethereum signed message prefix
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );

        return ecrecover(prefixedHash, v, r, s);
    }
}
