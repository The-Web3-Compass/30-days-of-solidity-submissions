// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EventEntry{
    string public eventName;
    address public organizer;
    uint256 public eventDate;
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    bool public isEventActive;

    mapping(address => bool) public hasAttended;

    event EventCreated(string name,uint256 date,uint256 maxAttendees);
    event AttendeeCheckedIn(address attendee, uint256 timestamp);
    event EventStatusChanged(bool isActive);

    constructor(string memory _eventName,uint256 _eventDate,uint256 _maxAttendees){
        eventName = _eventName;
        eventDate = _eventDate;
        maxAttendees = _maxAttendees;
        organizer = msg.sender;
        isEventActive = true;

        emit EventCreated(eventName, eventDate, maxAttendees);
    }

    modifier onlyOrganizer(){
        require(msg.sender == organizer,"not the event organizer");
        _;
    }

    function setEventStatus() external onlyOrganizer{
        isEventActive = !isEventActive;
        emit EventStatusChanged(isEventActive);
    }

    //off chain signature
    function getMessageHash(address _attendee) public view returns (bytes32){
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",_messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash,bytes memory _signature) 
        public
        pure 
        returns(address)    //与msg.sender compare
    {
        require(_signature.length == 65,"Invalid signature length");

        //assembly to extract those values
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly{
            r := mload(add(_signature,32))
            s := mload(add(_signature,64))
            v := byte(0,mload(add(_signature,96)))
        }

        if(v < 27) v += 27;
        require(v == 27 || v == 28,"Invalid signature, v error");

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function verifySignature(address _attendee, bytes memory _signature) public view returns(bool){
        bytes32 _messageHash = getMessageHash(_attendee);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;
    }

    //check in everyone
    function checkIn(bytes memory _signature) external{
        require(isEventActive,"Event is not activate");
        require(block.timestamp <= eventDate + 1 days,"Event ended");
        require(!hasAttended[msg.sender], "already checked");
        require(attendeeCount < maxAttendees, "Maximum attendees reached");
        require(verifySignature(msg.sender,_signature),"Invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender,block.timestamp);
    }
}