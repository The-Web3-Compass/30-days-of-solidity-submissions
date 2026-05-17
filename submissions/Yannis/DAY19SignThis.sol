// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract SignThis {
    
    string public eventName;
    address public organizer;
    uint256 public eventDate;       
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    bool public isEventActive;

   
    mapping(address => bool) public hasAttended;

    
    mapping(address => uint256) public nonces;

    
    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    event AttendeeCheckedIn(address indexed attendee, uint256 timestamp, uint256 nonce);
    event EventStatusChanged(bool isActive);

    
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer");
        _;
    }

    modifier eventOpen() {
        require(isEventActive, "Event not active");
        _;
    }

    
    constructor(string memory _eventName, uint256 _eventDate, uint256 _maxAttendees) {
        eventName = _eventName;
        organizer = msg.sender;
        eventDate = _eventDate;
        maxAttendees = _maxAttendees;
        isEventActive = true;

        emit EventCreated(_eventName, _eventDate, _maxAttendees);
    }

    
    function toggleEventStatus() external onlyOrganizer {
        isEventActive = !isEventActive;
        emit EventStatusChanged(isEventActive);
    }

    
    function getMessageHash(address _attendee, uint256 _nonce) public view returns (bytes32) {
        
        return keccak256(abi.encodePacked(address(this), eventName, _attendee, _nonce));
    }

    
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    
    function recoverSigner(bytes32 _ethSignedMessageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    
    function verifySignature(address _attendee, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_attendee, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signer = recoverSigner(ethSignedMessageHash, v, r, s);
        return signer == organizer;
    }

    
    function checkInWithSignature(
        address _attendee,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 _nonce
    ) public eventOpen {
        
        require(block.timestamp <= eventDate + 1 days, "Event has ended");
        require(attendeeCount < maxAttendees, "Event full");
        require(!hasAttended[_attendee], "Already checked in");

        
        require(_nonce == nonces[_attendee], "Invalid nonce");

        
        require(verifySignature(_attendee, _nonce, v, r, s), "Invalid signature");

        
        hasAttended[_attendee] = true;
        attendeeCount++;
        nonces[_attendee]++; 

        emit AttendeeCheckedIn(_attendee, block.timestamp, _nonce);
    }

    
    function batchCheckIn(
        address[] calldata attendees,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s,
        uint256[] calldata noncesArr
    ) external eventOpen {
        uint256 len = attendees.length;
        require(len == v.length && len == r.length && len == s.length && len == noncesArr.length, "Array length mismatch");
        require(attendeeCount + len <= maxAttendees, "Would exceed capacity");

        for (uint256 i = 0; i < len; i++) {
            address at = attendees[i];

            
            if (hasAttended[at]) { continue; }

            
            if (noncesArr[i] != nonces[at]) { continue; }

            
            bool ok = verifySignature(at, noncesArr[i], v[i], r[i], s[i]);
            if (!ok) { continue; }

            
            hasAttended[at] = true;
            attendeeCount++;
            nonces[at]++; 

            emit AttendeeCheckedIn(at, block.timestamp, noncesArr[i]);
        }
    }

    
    function checkSignatureValid(address _attendee, uint8 v, bytes32 r, bytes32 s, uint256 _nonce) external view returns (bool) {
        
        if (_nonce != nonces[_attendee]) return false;
        return verifySignature(_attendee, _nonce, v, r, s);
    }

    
    function bumpNonce(address _attendee) external onlyOrganizer {
        nonces[_attendee]++;
    }

   
    function getEventInfo() external view returns (
        string memory name,
        uint256 date,
        uint256 maxCapacity,
        uint256 currentCount,
        bool active
    ) {
        return (eventName, eventDate, maxAttendees, attendeeCount, isEventActive);
    }
}
