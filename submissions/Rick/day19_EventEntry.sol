// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventEntry {
    // 活动名称
    string public eventName;
    // 活动管理者
    address public organizer;
    // 活动日期
    uint256 public eventDate;
    // 活动最多参加人数
    uint256 public maxAttendees;
    // 签到人数
    uint256 public attendeeCount;
    // 活动开启状态
    bool public isEventActive;

    // 报名用户
    mapping(address => bool) public hasAttended;

    // 活动合约发布成功
    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    // 用户报名成功
    event AttendeeCheckedIn(address attendee, uint256 timestamp);
    // 活动转态变更
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
        require(msg.sender == organizer, "Only the event organizer can call this function");
        _;
    }

    // 管理者变更活动状态
    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    /*
        keccak256 solidity内置的hash函数，返回bytes32 
        返回 bytes32（固定 32 字节）。
        输入是 bytes（任意长度），通常通过 abi.encode / abi.encodePacked 生成。

        abi.encode() abi标准编码、包含类型信息、固定长度对齐，padding补齐
        abi.encodePacked() 紧凑编码、不包含类型信息、字符串直接拼接，无padding，有hahs碰撞风险

        encode 安全有边界，encodePacked 紧凑但易碰撞。
    */
    function getMessageHash(address _attendee) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    /*
        "\x19Ethereum Signed Message:\n32 是以太坊消息签名机制的安全前缀， 主要是为了防止签名重放攻击和跨合约伪造签名
        出自EIP-191签名标准

    */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    // 验证签名 
    function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_attendee);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;
    }

    // 签名有效（确实由 organizer 签）
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address){
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // 因为 Solidity 的 bytes 类型在内存中前 32 字节是长度信息，所以真实数据从偏移量 +32 开始
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "Invalid signature 'v' value");
        /*
            ecrecover
            作用一：验证签名合法性
            作用二：找到用户公钥，进而获取用户地址
        */
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    //签到
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