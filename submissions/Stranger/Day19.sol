// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignThis {
    string public eventName;       // 活动名
    address public organizer;      // 组织者
    uint256 public eventDate;      // 活动日期
    uint256 public maxAttendees;   // 最大参与人数
    uint256 public attendeeCount;  // 实到人数
    bool public isEventActive;     // 活动是否处于有效状态

    mapping(address => bool) public hasAttended;  // 标识用户是否已经签到的映射

    // 定义3个事件: 活动创建, 参与人签到, 活动状态变更
    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    event AttendeeCheckedIn(address attendee, uint256 timestamp);
    event EventStatusChanged(bool isActive);

    constructor(string memory _eventName, uint256 _eventDate, uint256 _maxAttendees) {
        eventName = _eventName;
        organizer = msg.sender;
        eventDate = _eventDate;
        maxAttendees = _maxAttendees;
        isEventActive = true;

        emit EventCreated(_eventName, _eventDate, _maxAttendees);
    }

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer available");
        _;
    }

    modifier eventActive() {
        require(isEventActive, "Event not active");
        _;
    }

    // 使用签名验证参与者身份
    function checkInWithSignature(address attendee, uint8 v, bytes32 r, bytes32 s) external eventActive {
        require(attendeeCount < maxAttendees, "Exceed capacity");
        require(!hasAttended[attendee], "Already checked in");

        // 构造消息哈希
        bytes32 messageHash = keccak256(abi.encodePacked(
            attendee,
            address(this),  // 合约地址
            eventName
        ));

        // 以太坊签名消息哈希
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));

        // 恢复签名者地址
        address signer = ecrecover(ethSignedMessageHash, v, r, s);

        // 验证签名者是组织者
        require(signer == organizer, "Invalid signature");

        // 修改签到状态及实到人数
        hasAttended[attendee] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(attendee, block.timestamp);
    }

    // 批量签到 (Gas优化)
    function batchCheckIn(
        address[] calldata attendees,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external eventActive {
        require(attendees.length == v.length, "Array length mismatch");
        require(attendees.length == r.length, "Array length mismatch");
        require(attendees.length == s.length, "Array length mismatch");
        require(attendeeCount + attendees.length <= maxAttendees, "Would exceed capacity");

        for (uint256 i = 0; i < attendees.length; i++) {
            address attendee = attendees[i];

            if (hasAttended[attendee]) continue;  // 跳过已签到的

            bytes32 messageHash = keccak256(abi.encodePacked(
                attendee,
                address(this),
                eventName
            ));

            bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                messageHash
            ));

            address signer = ecrecover(ethSignedMessageHash, v[i], r[i], s[i]);

            if (signer == organizer) {
                hasAttended[attendee] = true;
                attendeeCount++;
                emit AttendeeCheckedIn(attendee, block.timestamp);
            }
        }
    }

    // 验证签名有效性 (不执行签到)
    function verifySignature(
        address attendee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(
            attendee,
            address(this),
            eventName
        ));

        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));

        address signer = ecrecover(ethSignedMessageHash, v, r, s);
        return signer == organizer;
    }

    // 获取消息哈希 (用于前端签名)
    function getMessageHash(address attendee) external view returns (bytes32) {
        return keccak256(abi.encodePacked(
            attendee,
            address(this),
            eventName
        ));
    }

    // 转换活动状态
    function toggleEventStatus() external onlyOrganizer {
        isEventActive = !isEventActive;
        emit EventStatusChanged(isEventActive);
    }

    // 获取活动信息
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