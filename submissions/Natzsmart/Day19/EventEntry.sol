// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title EventEntry - A smart contract for Web3 event check-in using signed messages
contract EventEntry {
    // Basic event configuration
    string public eventName;
    address public organizer;
    uint256 public eventDate;
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    bool public isEventActive;

    // Track which addresses have checked in
    mapping(address => bool) public hasAttended;

    // Events for off-chain logging
    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    event AttendeeCheckedIn(address attendee, uint256 timestamp);
    event EventStatusChanged(bool isActive);

    /// @notice Initializes the event details
    /// @param _eventName The name of the event
    /// @param _eventDate The start time of the event (UNIX timestamp)
    /// @param _maxAttendees The maximum number of attendees allowed
    constructor(string memory _eventName, uint256 _eventDate, uint256 _maxAttendees) {
        eventName = _eventName;
        eventDate = _eventDate;
        maxAttendees = _maxAttendees;
        organizer = msg.sender;
        isEventActive = true;

        emit EventCreated(_eventName, _eventDate, _maxAttendees);
    }

    /// @notice Restricts function access to the event organizer only
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer");
        _;
    }

    /// @notice Enables or disables the event
    /// @param _isActive The new status of the event
    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    /// @notice Checks if the event has expired (more than 1 day after the event date)
    function isEventExpired() public view returns (bool) {
        return block.timestamp > eventDate + 1 days;
    }

    /// @notice Generates the message hash used for off-chain signing
    /// @param _attendee The address of the attendee
    function getMessageHash(address _attendee) public view returns (bytes32) {
        return keccak256(abi.encodePacked(block.chainid, address(this), eventName, eventDate, _attendee));
    }

    /// @notice Prefixes the message hash to conform with the `eth_sign` standard
    /// @param _messageHash The raw message hash
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /// @notice Verifies that the signature was signed by the organizer for the given attendee
    /// @param _attendee The attendee address
    /// @param _signature The signature signed by the organizer
    function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_attendee);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address recovered = recoverSigner(ethSignedMessageHash, _signature);
        return recovered != address(0) && recovered == organizer;
    }

    /// @notice Recovers the signer from the signed message
    /// @param _ethSignedMessageHash The prefixed message hash
    /// @param _signature The 65-byte signature (r, s, v)
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract r, s, v from the signature using assembly
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) v += 27;
        require(v == 27 || v == 28, "Invalid signature v value");

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /// @notice Allows a guest to check in by submitting a valid signature from the organizer
    /// @param _signature A valid signature generated off-chain for this attendee
    function checkIn(bytes memory _signature) external {
        require(isEventActive, "Event not active");
        require(block.timestamp >= eventDate, "Event hasn't started");
        require(!isEventExpired(), "Event has expired");
        require(!hasAttended[msg.sender], "Already checked in");
        require(attendeeCount < maxAttendees, "Max attendees reached");
        require(verifySignature(msg.sender, _signature), "Invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender, block.timestamp);
    }
}