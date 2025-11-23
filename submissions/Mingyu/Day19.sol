// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignThis {
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
    event SignatureVerified(address attendee, bool isValid);

    constructor(string memory _eventName, uint256 _eventDate, uint256 _maxAttendees) {
        eventName = _eventName;
        organizer = msg.sender;
        eventDate = _eventDate;
        maxAttendees = _maxAttendees;
        isEventActive = true;

        emit EventCreated(_eventName, _eventDate, _maxAttendees);
    }

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer can call this");
        _;
    }

    modifier eventActive() {
        require(isEventActive, "Event is not active");
        _;
    }

    // 签名验证逻辑
    function _verifySignature(address attendee, uint8 v, bytes32 r, bytes32 s) private view returns (address) {
        bytes32 messageHash = keccak256(abi.encodePacked(
            attendee,
            address(this),
            eventName
        ));

        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    // 使用签名进行签到
    function checkInWithSignature(
        address attendee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external eventActive {
        require(attendeeCount < maxAttendees, "Event is full");
        require(!hasAttended[attendee], "Already checked in");

        // 验证签名是否由组织者签署
        address signer = _verifySignature(attendee, v, r, s);
        require(signer == organizer, "Invalid signature");

        // 更新签到记录
        hasAttended[attendee] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(attendee, block.timestamp);
    }

    // 批量签到
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

            if (hasAttended[attendee]) continue; // Skip already checked-in attendees

            // 验证签名
            address signer = _verifySignature(attendee, v[i], r[i], s[i]);
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
        address signer = _verifySignature(attendee, v, r, s);
        bool isValid = signer == organizer;
        emit SignatureVerified(attendee, isValid);
        return isValid;
    }

    // 获取消息哈希 (用于前端签名)
    function getMessageHash(address attendee) external view returns (bytes32) {
        return keccak256(abi.encodePacked(
            attendee,
            address(this),
            eventName
        ));
    }

    // 管理员功能：切换活动状态（激活/停用）
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
