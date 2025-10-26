// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EventEntry {
    string public eventName; //活动名称
    address public organizer; //活动组织者地址
    uint256 public eventDate; //事件的预定时间
    uint256 public maxAttendees; //入住人数上限
    uint256 public attendeeCount; //最大出席人数
    bool public isEventActive; //是否接受签到

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
        require(msg.sender == organizer, "only the event organizer can call this function");
        _;
    }

    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);

    }

    //生成基础信息哈希
    function getMessageHash(address _attendee) public view returns (byte32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));

    }

    //转换为以太坊签名格式
    function getEthSignedMessageHash(byte32 _messageHash) public pure returns (byte32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));

    }

    //签名验证
    functioin verifySignature(address _attendee, byte32 memory _signature) public view returns (bool) {
        byte32 messageHash = getMessageHash(_attendee);
        byte32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;

    }

    //恢复签名者
    function recoverSigner(byte32 _ethSignedMessageHash, byte32 memory _signature) public pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");
        byte32 r;
        byte32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if(v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "invalid signature 'v' value");

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    functioin checkIn(bytes memory _signature) external {
        require(isEventActive, "Event is not active");
        require(block.timestamp <= eventDate + 1 days, "event has ended");
        require(!hasAttended[msg.sender], "Attendee has already checked in");
        require(attendeeCount < maxAttendees, "maximum attendees reached");
        require(verifySignature(msg.sender, _signature), "Invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender, block.timestamp);

    }

}