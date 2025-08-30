// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract EventEntry {
    string public eventName;
    address public organizer;
    uint public eventDate;
    uint public maxAttendees;
    uint public attendeeCount;
    bool public isEventActive;
    mapping(address => bool) hasAttended;

    event EventCreated(string eventName,uint date, uint maxAttendees );
    event AttendeeCheckedIn(address attendee, uint timestamp);

    constructor(string memory _eventName, uint _eventDate, uint _maxAttendees){
        eventName = _eventName;
        eventDate = _eventDate;
        maxAttendees = _maxAttendees;
        organizer = msg.sender;
        isEventActive = true;

        emit EventCreated(_eventName, block.timestamp, _maxAttendees);
    }

    modifier onlyOrganizer() {
        require(organizer == msg.sender, "unauthorized");
        _;
    }

    function setStatus(bool _eventStatus) public onlyOrganizer() {
        isEventActive = _eventStatus;
    }
    
    function getMessageHash(address _attendee) public view returns(bytes32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verifySignature(address _attendee, bytes memory  _signature) public view returns(bool){
        bytes32 messageHash = getMessageHash(_attendee);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return (recoverSigner(ethSignedMessageHash, _signature) == organizer);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns(address){
        require(_signature.length == 65, "invalid length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly{
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if(v <27){
            v+=27;
        }

        require(v==27 || v== 28, "invalid signature");

        return ecrecover(_ethSignedMessageHash, v, r, s);

    }

    function checkIn(bytes memory _signature) public {
        require(isEventActive == true, "event has ended");
        require(attendeeCount < maxAttendees, "max attendeed" );
        require(eventDate <= block.timestamp + 1 days, "event has ended" );
        require(attendeeCount < maxAttendees, "max attendeed" );
        require(!hasAttended[msg.sender] , "already checked in");
        require(verifySignature(msg.sender, _signature), "invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender, block.timestamp);
    }
}