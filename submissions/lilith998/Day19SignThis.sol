// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract PrivateEventAccess {
    address public immutable eventOrganizer;
    uint256 public constant ENTRY_FEE = 0.05 ether;
    
    // Track which tickets have been used
    mapping(bytes32 => bool) private _usedTickets;
    
    event GuestVerified(address guest, uint256 eventId);
    event EntryGranted(address guest, uint256 eventId);
    event OrganizerChanged(address newOrganizer);

    constructor(address _organizer) {
        eventOrganizer = _organizer;
    }

    /**
     * @dev Verify ticket signature and grant entry
     * @param eventId Unique event identifier
     * @param validUntil Signature expiration timestamp
     * @param signature Signature from event organizer
     */
    function verifyAndEnter(
        uint256 eventId,
        uint256 validUntil,
        bytes memory signature
    ) external payable {
        require(msg.value >= ENTRY_FEE, "Insufficient entry fee");
        require(block.timestamp <= validUntil, "Ticket expired");
        
        bytes32 ticketHash = getTicketHash(
            msg.sender,
            eventId,
            validUntil,
            address(this)
        );
        
        require(!_usedTickets[ticketHash], "Ticket already used");
        require(verifySignature(ticketHash, signature), "Invalid signature");
        
        _usedTickets[ticketHash] = true;
        
        emit GuestVerified(msg.sender, eventId);
        grantEntry(eventId);
    }

    /**
     * @dev Grant entry to the event (could be extended with custom logic)
     * @param eventId Unique event identifier
     */
    function grantEntry(uint256 eventId) internal {
        // Add custom entry logic here (NFT minting, access tokens, etc)
        emit EntryGranted(msg.sender, eventId);
    }

    /**
     * @dev Generate the ticket hash that was signed
     * @param guest Guest address
     * @param eventId Event identifier
     * @param validUntil Signature expiration time
     * @param contractAddress Current contract address
     */
    function getTicketHash(
        address guest,
        uint256 eventId,
        uint256 validUntil,
        address contractAddress
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                guest,
                eventId,
                validUntil,
                contractAddress
            )
        );
    }

    /**
     * @dev Verify the signature against organizer's address
     * @param dataHash Hash of ticket data
     * @param signature Signature to verify
     */
    function verifySignature(
        bytes32 dataHash,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
        );
        
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        address signer = ecrecover(ethSignedHash, v, r, s);
        
        return signer == eventOrganizer;
    }

    /**
     * @dev Split signature into r, s, v components
     * @param sig Combined signature
     */
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /**
     * @dev Withdraw collected entry fees
     */
    function withdrawFees() external {
        require(msg.sender == eventOrganizer, "Unauthorized");
        payable(eventOrganizer).transfer(address(this).balance);
    }

    /**
     * @dev Check if a ticket has been used
     * @param guest Guest address
     * @param eventId Event identifier
     * @param validUntil Signature expiration time
     */
    function isTicketUsed(
        address guest,
        uint256 eventId,
        uint256 validUntil
    ) external view returns (bool) {
        bytes32 ticketHash = getTicketHash(
            guest,
            eventId,
            validUntil,
            address(this)
        );
        return _usedTickets[ticketHash];
    }
}