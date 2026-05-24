// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simplified ECDSA logic since we might not have OpenZeppelin installed in this environment
library SignatureUtils {
    function getMessageHash(address _user) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

contract SignThis {
    address public organizer;
    mapping(address => bool) public hasEntered;

    constructor() {
        organizer = msg.sender;
    }

    function enterEvent(bytes memory signature) external {
        require(!hasEntered[msg.sender], "Already entered");

        // 1. Recreate the hash that was signed (the user's address)
        bytes32 messageHash = SignatureUtils.getMessageHash(msg.sender);
        
        // 2. Add the "Ethereum Signed Message" prefix
        bytes32 ethSignedMessageHash = SignatureUtils.getEthSignedMessageHash(messageHash);

        // 3. Recover the signer address from the signature
        address signer = SignatureUtils.recoverSigner(ethSignedMessageHash, signature);

        // 4. Check if it matches the organizer
        require(signer == organizer, "Invalid signature");

        // 5. Success!
        hasEntered[msg.sender] = true;
    }
}