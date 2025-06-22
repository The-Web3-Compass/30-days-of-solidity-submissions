// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EventEntry{
    /**
    The event organizer signs a message off-chain for each approved attendee.
    The attendee then brings that signed message on-chain to prove they were invited.
    */

    string public eventName;
    // owner
    address public organizer;
    uint256 public eventDate;
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    bool public isEventActive;

    mapping(address => bool) public hasAttended;

    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    event AttendeeCheckedIn(address attendee, uint256 timestamp);
    event EventStatusChanged(bool isActive);

    constructor(string memory _eventName, uint256 _eventDate_unix, uint256 _maxAttendees) {
        eventName = _eventName;
        eventDate = _eventDate_unix;
        maxAttendees = _maxAttendees;
        organizer = msg.sender;
        isEventActive = true;

        emit EventCreated(_eventName, _eventDate_unix, _maxAttendees);
    }

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only the event organizer can call this function");
        _;
    }

    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    /**
    When a user signs data off-chain (like a hash of a message), 
    they’re technically signing any random 32 bytes. 
    That could include the hash of a transaction, the hash of a contract, or some completely unrelated data.
    */
    function getMessageHash(address _attendee) public view returns(bytes32) {
        // Taking your original message hash and wraps it with a prefix.
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns(bytes32) {
        // "\x19Ethereum Signed Message:\n32" + messageHash
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verifySignature(address _attendee, bytes memory _signature) public view returns(bool) {
        // This recreates the exact hash that the organizer signed off-chain for a specific attendee.
        bytes32 messageHash = getMessageHash(_attendee);
        // This wraps the message hash with Ethereum’s standard prefix
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)public pure returns(address){
        require(_signature.length == 65, "Invalid signature length");
        // These three values work together to mathematically prove who signed the message.
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            //  (string,position)
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) v += 27;

        require(v == 27 || v == 28, "Invalid signature 'v' value");

        // The signed message hash
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function checkIn(bytes memory _signature) external {
        require(isEventActive, "Event is not active");
        // You can only check in until 24 hours after the event date.
        require(block.timestamp <= eventDate + 1 days, "Event has ended");
        require(!hasAttended[msg.sender], "Attendee has already checked in");
        require(attendeeCount < maxAttendees, "Maximum attendees reached");
        require(verifySignature(msg.sender, _signature), "Invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender, block.timestamp);
    }
}