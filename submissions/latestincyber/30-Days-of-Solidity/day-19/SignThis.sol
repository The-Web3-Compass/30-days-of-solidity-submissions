// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignThis {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public organizer;
    mapping(address => bool) public hasEntered;

    constructor() {
        organizer = msg.sender;
    }

    /* 
     * @dev User provides a signature. We verify if the 'organizer' signed it.
     * The message signed is simply the user's address.
     */
    function enterEvent(bytes memory signature) external {
        require(!hasEntered[msg.sender], "Already entered");

        // 1. Recreate the hash that was signed
        // We hash the msg.sender because the permission slip is bound to THEIR address.
        // They can't give it to someone else.
        bytes32 messageHash = keccak256(abi.encode(address(this), block.chainid, msg.sender));
        
        // 2. Add the "Ethereum Signed Message" prefix (standard security practice)
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        // 3. Recover the signer address from the signature
        address signer = ethSignedMessageHash.recover(signature);

        // 4. Check if it matches the organizer
        require(signer == organizer, "Invalid signature");

        // 5. Success!
        hasEntered[msg.sender] = true;
    }
}