
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

library ECDSA {
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) return address(0);
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (v < 27) v += 27;
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }
}

library MessageHashUtils {
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }
}

contract SignThis {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public organizer;
    mapping(address => bool) public hasEntered;
    mapping(address => uint256) public nonces;

    constructor() {
        organizer = msg.sender;
    }

    /**
     * @dev User provides a signature to enter the event. 
     *      Verifies if the 'organizer' signed their address along with a nonce to prevent replay attacks.
     */
    function enterEvent(bytes memory signature, uint256 nonce) external {
        require(!hasEntered[msg.sender], "Already entered");
        require(nonce == nonces[msg.sender], "Invalid nonce");

        // 1. Recreate the hash that was signed
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, nonce));
        
        // 2. Add the "Ethereum Signed Message" prefix 
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        // 3. Recover the signer address from the signature
        address signer = ethSignedMessageHash.recover(signature);

        // 4. Check if it matches the organizer
        require(signer == organizer, "Invalid signature");

        // 5. Success! Iterate nonce and mark entered
        nonces[msg.sender]++;
        hasEntered[msg.sender] = true;
    }
}
