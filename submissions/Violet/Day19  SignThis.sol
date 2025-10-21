// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title EventEntry
 * @dev 使用签名验证来管理活动入场，高效且节省Gas。
 */
contract EvenSignThis {
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

    /**
     * @dev 构造函数，在部署时设置活动的基本信息。
     */
    constructor(string memory _eventName, uint256 _eventDate_unix, uint256 _maxAttendees) {
        eventName = _eventName;
        eventDate = _eventDate_unix;
        maxAttendees = _maxAttendees;
        organizer = msg.sender;
        isEventActive = true;

        emit EventCreated(_eventName, _eventDate_unix, _maxAttendees);
    }

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only the event organizer can call this function");
        _;
    }

    /**
     * @dev 组织者可以暂停或恢复活动。
     */
    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    /**
     * @dev 生成需要被签名的消息哈希。
     * 这个哈希是独一无二的，它绑定了合约、活动和嘉宾地址。
     */
    function getMessageHash(address _attendee) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    /**
     * @dev 为消息哈希添加以太坊标准前缀，为验证做准备。
     */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /**
     * @dev 验证签名是否由组织者为指定嘉宾签署。
     */
    function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_attendee);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;
    }

    /**
     * @dev 从签名和消息哈希中恢复出签名者的地址。
     */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev 嘉宾使用签名进行签到。
     */
    function checkIn(bytes memory _signature) external {
        require(isEventActive, "Event is not active");
        require(block.timestamp <= eventDate + 1 days, "Event has ended");
        require(!hasAttended[msg.sender], "Attendee has already checked in");
        require(attendeeCount < maxAttendees, "Maximum attendees reached");
        require(verifySignature(msg.sender, _signature), "Invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender, block.timestamp);
    }
}

