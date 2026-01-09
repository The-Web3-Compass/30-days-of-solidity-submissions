// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EventEntry {
    string public eventName;
    address public immutable organizer; 
    uint256 public eventDate;
    uint256 public immutable maxAttendeeCount;
    uint256 public attendeeCount;
    bool public isEventActive;

    mapping(address => bool) public hasAttended;

    bytes32 private constant ETHEREUM_MESSAGE_PREFIX = keccak256("\x19Ethereum Signed Message:\n32");

    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    event AttendeeCheckedIn(address attendee, uint256 timestamp);
    event EventStatusChanged(bool isActive);

    error OnlyOrganizerAllowed();
    error EventNotActive();
    error EventNotStarted();
    error EventEnded();
    error AlreadyCheckedIn();
    error MaxAttendeesReached();
    error InvalidSignature();

    constructor(string memory _eventName, uint256 _eventDate_unix, uint256 _maxAttendees) {
        eventName = _eventName;
        eventDate = _eventDate_unix;
        maxAttendeeCount = _maxAttendees;
        organizer = msg.sender;
        isEventActive = true;
        emit EventCreated(_eventName, _eventDate_unix, _maxAttendees);
    }

    modifier onlyOrganizer() {
        if (msg.sender != organizer) revert OnlyOrganizerAllowed();
        _;
    }

    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    function getMessageHash(address _attendee) public view returns(bytes32) {
        return keccak256(abi.encode(address(this), eventName, _attendee));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(ETHEREUM_MESSAGE_PREFIX, _messageHash));
    }

    function verifySignature(address _attendee, bytes calldata _signature) public view returns(bool) {
        bytes32 messageHash = getMessageHash(_attendee);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes calldata _signature) public pure returns(address) {
        if (_signature.length != 65) revert InvalidSignature();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := calldataload(add(_signature.offset, 0))
            s := calldataload(add(_signature.offset, 32))
            v := byte(0, calldataload(add(_signature.offset, 64)))
        }

        if (v < 27) v += 27;

        if (v != 27 && v != 28) revert InvalidSignature();
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function checkIn(bytes calldata _signature) external {
        if (!isEventActive) revert EventNotActive();
        if (block.timestamp < eventDate) revert EventNotStarted();
        if (block.timestamp > eventDate + 1 days) revert EventEnded();
        if (hasAttended[msg.sender]) revert AlreadyCheckedIn();
        if (attendeeCount >= maxAttendeeCount) revert MaxAttendeesReached();
        if (!verifySignature(msg.sender, _signature)) revert InvalidSignature();

        hasAttended[msg.sender] = true;
        unchecked { attendeeCount++; } 

        emit AttendeeCheckedIn(msg.sender, block.timestamp);
    }
}