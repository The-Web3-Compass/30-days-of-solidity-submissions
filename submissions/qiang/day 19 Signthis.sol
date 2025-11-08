// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract EventEntry{

    string public eventName;
    address public organizer;
    uint256 public eventDate;
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    bool public isEventActive;

    mapping (address => bool) public hasAttended;

    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    event AttendeeCheckedIn(address attendee, uint256 timestamp);
    event EventStatusChange(bool isEventActive);

    constructor(string memory _eventName, uint256 _eventDate, uint256 _maxAttendees){
        eventName = _eventName;
        eventDate = _eventDate;
        maxAttendees = _maxAttendees;
        organizer = msg.sender;
        isEventActive = true;

        emit EventCreated(_eventName, _eventDate, _maxAttendees);

    }

    modifier onlyOrganizer(){
        require(msg.sender == organizer,"Only the organizer can call this function");
        _;
    }

    function setEventStatus(bool _isActive) external onlyOrganizer{
        isEventActive = _isActive;
        emit EventStatusChange(_isActive);
    }

    function getMessageHash(address _attendee) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    function getEthSignedMassageHash(bytes32 _massageHash) public pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Massage: \n32", _massageHash));
    }

    function verifySignature(address _attendee, bytes memory _signature)public view returns(bool)
    {

        bytes32 messageHash = getMessageHash(_attendee);
        bytes ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner();
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory _signature) public pure returns (address){

        require(_signature.length == 65,"Invalid Length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly{
            r := molad(add(_signature, 32))
            s :=mload(add(_signature, 64))
            v := byte(0,molad(add(_signature,96)))
        }
        if(v < 27){v+=27;
        }
        return (v ==27 || v==28,"Invalid signature 'v'value");
        
        return ecrecover(ethSignedMessageHash,v,r,s);



    }

    function checkIn(bytes memory _signature) external{
        require(isEventActive, "Event not active");
        require(block.timestamp <= eventDate +1 days,"Event ended");
        require(!hasAttended[msg.sender],"attend has already checked in");
        require(attendeeCount < maxAttendees, "max attendees reached");
        require(verifySignature(msg.sender, _signature),"Invalid Signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;
        emit AttendeeCheckedIn(msg.sender, block.timestamp);

    }


}
