// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventAccessControl {
    address public organizer;
    mapping(bytes32 => bool) public usedSignatures;
    
    event GuestVerified(address indexed guest, uint256 eventId);
    event OrganizerChanged(address indexed newOrganizer);
    
    constructor() {
        organizer = msg.sender;
    }
    
    function verifyAccess(
        uint256 eventId,
        uint256 validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        require(block.timestamp <= validUntil, "Signature expired");
        
        
        bytes32 innerHash = keccak256(abi.encodePacked(msg.sender, eventId, validUntil));
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                innerHash
            )
        );
        
        address signer = ecrecover(messageHash, v, r, s);
        require(signer == organizer, "Invalid signature");
        
        bytes32 signatureId = keccak256(abi.encodePacked(r, s, v));
        require(!usedSignatures[signatureId], "Signature already used");
        
        usedSignatures[signatureId] = true;
        emit GuestVerified(msg.sender, eventId);
    }
    
    function changeOrganizer(address newOrganizer) external {
        require(msg.sender == organizer, "Organizer only");
        organizer = newOrganizer;
        emit OrganizerChanged(newOrganizer);
    }
    
    function generateMessageHash(
        address guest,
        uint256 eventId,
        uint256 validUntil
    ) external pure returns (bytes32) {
        bytes32 innerHash = keccak256(abi.encodePacked(guest, eventId, validUntil));
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                innerHash
            )
        );
    }
}
