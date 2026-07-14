// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title EventEntry
/// @notice 使用签名验证机制控制参与者打卡入场的活动合约
contract EventEntry {
    string public eventName;
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
        require(msg.sender == organizer, "Only organizer");
        _;
    }

    // ========== Organizer Controls ==========

    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    // ========== Signature Logic ==========

    /// @notice Returns the keccak256 message hash used for signing
    function getMessageHash(address _attendee) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    /// @notice Returns the Ethereum-signed message hash
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /// @notice Verifies that a signature was signed by the organizer for a specific attendee
    function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_attendee);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;
    }

    /// @notice Recovers the signer from the signature
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) v += 27;
        require(v == 27 || v == 28, "Invalid signature v");

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // ========== Check-In Entry ==========

    /// @notice Attendee checks in using a signature signed by the organizer
    function checkIn(bytes memory _signature) external {
        require(isEventActive, "Event is not active");
        require(block.timestamp <= eventDate + 1 days, "Event ended");
        require(!hasAttended[msg.sender], "Already checked in");
        require(attendeeCount < maxAttendees, "Max attendees reached");
        require(verifySignature(msg.sender, _signature), "Invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender, block.timestamp);
    }
}
