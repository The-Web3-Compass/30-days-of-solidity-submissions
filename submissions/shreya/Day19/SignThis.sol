// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import the library for its 'recover' function.
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract SignEvent {
    using ECDSA for bytes32;

    // --- State Variables ---
    string public eventName;
    address public organizer;
    uint256 public eventDate;
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    bool public isEventActive;

    mapping(address => bool) public hasAttended;

    // --- Events ---
    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    event AttendeeCheckedIn(address indexed attendee, uint256 timestamp);
    event EventStatusChanged(bool isActive);

    // --- Modifiers ---
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "EventEntry: Only the organizer can call this function");
        _;
    }

    constructor(string memory _eventName, uint256 _eventDate_unix, uint256 _maxAttendees) {
        eventName = _eventName;
        eventDate = _eventDate_unix;
        maxAttendees = _maxAttendees;
        organizer = msg.sender;
        isEventActive = true;
        emit EventCreated(_eventName, _eventDate_unix, _maxAttendees);
    }

    // --- Administrative Functions ---
    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    // --- Public View Functions ---
    function getMessageHash(address _attendee) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    // --- Core Check-In Function ---
    function checkIn(bytes memory _signature) external {
        // --- Pre-condition checks ---
        require(isEventActive, "EventEntry: Event is not active");
        require(block.timestamp <= eventDate + 1 days, "EventEntry: Event has ended");
        require(!hasAttended[msg.sender], "EventEntry: Attendee has already checked in");
        require(attendeeCount < maxAttendees, "EventEntry: Maximum attendees reached");

        // --- Secure Signature Verification ---
        bytes32 messageHash = getMessageHash(msg.sender);

        // --- FIX: Manually construct the EIP-191 signed message hash for backward compatibility ---
        // This line performs the same action as the newer .toEthSignedMessageHash() helper function.
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        // The rest of the logic remains the same. We use the library for the complex 'recover' part.
        address recoveredSigner = ethSignedMessageHash.recover(_signature);
        
        require(recoveredSigner == organizer, "EventEntry: Invalid signature");
        require(recoveredSigner != address(0), "EventEntry: Signature recovery failed");

        // --- State Updates ---
        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender, block.timestamp);
    }
}