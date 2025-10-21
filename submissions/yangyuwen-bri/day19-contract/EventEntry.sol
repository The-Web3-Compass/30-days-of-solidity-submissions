// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract EventEntry {
    string public eventName;
    address public organizer;
    uint256 public eventDate; //Example: 1714569600 → April 30, 2024 at 00:00:00 UTC
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    bool public isEventActive;

    mapping(address => bool) public hasAttended;

    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    event AttendeeCheckIn(address attendee, uint256 timestamp);
    event EventStatus(bool isActivate);

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "only organizer can perform this action,");
        _;
    }

    // 主办方部署合约
    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    constructor(string memory _eventName, uint256 _eventDate, uint256 _maxAttendees){
        eventName = _eventName;
        organizer = msg.sender;
        eventDate = _eventDate;
        maxAttendees = _maxAttendees;
        isEventActive = true;

        emit EventCreated(_eventName, _eventDate, _maxAttendees);
    }

    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatus(_isActive);
    }

    // 为嘉宾生成唯一哈希：输入嘉宾地址，得到messageHash填入js脚本，获取signature
    // 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    // 0x617F2E2fD72FD9D5503197092aC168c91465E7f2
    function getMessageHash(address _attendee) public view returns(bytes32){

        return(keccak256(abi.encodePacked(address(this), eventName, _attendee)));

    }

    // 加上以太坊签名标准前缀，变成钱包签名时的格式。
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    // 验证签名
    function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_attendee);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        // 以太坊的标准签名长度是65字节（r:32字节, s:32字节, v:1字节）
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        // 用低级的 assembly 语法直接从 _signature 里取出签名的三个部分
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // v 只能是 27 或 28（有些钱包会返回0或1，这里做兼容）。
        // 如果不是27或28，说明签名不合法。
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "Invalid signature 'v' value");

        // ecrecover 是以太坊的内置函数。
        // 输入：消息哈希、v、r、s
        // 输出：签名者的以太坊地址
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // 嘉宾签到：输入主办方给的数字签名
    function checkIn(bytes memory _signature) external{
        
        require(isEventActive, "Event is not active");
        require(block.timestamp <= eventDate + 1 days, "Event has ended");
        require(!hasAttended[msg.sender], "Attendee has already checked in");
        require(attendeeCount < maxAttendees, "Maximum attendees reached");
        require(verifySignature(msg.sender, _signature), "Invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckIn(msg.sender, block.timestamp);

    }


}