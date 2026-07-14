//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EventEntry {
    string public eventName;
    uint256 public eventTime;
    address public organiser;
    uint256 public maxAttendee;
    uint256 public attendeeCount;
    bool public isActive;

    mapping(address => bool) public hasAttended;

    event EventCreated(string _eventName, uint256 _eventTime, uint256 _maxAttendee);
    event AttendeeCheckdIn(address indexed _attendee, uint256 _timeCheckdIn);
    event EventStatusChanged(bool _status);

    constructor(string memory _eventName, uint256 _eventTime_unix, uint256 _maxAttendee) {
        eventName = _eventName;
        eventTime = _eventTime_unix;
        maxAttendee = _maxAttendee;
        organiser = msg.sender;
        isActive = true;
        emit EventCreated(_eventName, _eventTime_unix, _maxAttendee);
    }

    modifier onlyOrganiser() {
        require(msg.sender == organiser, "Only the event organiser can perform this action");
        _;
    }

    function setEventStatus(bool _isActive) external onlyOrganiser {
        isActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    function checkIn(bytes calldata _signature) external {
        require(isActive, "Event is not active");
        require(block.timestamp <= eventTime + 1 days, "Event is already ended");
        require(attendeeCount + 1 <= maxAttendee, "Maximun attandee reached");
        require(!hasAttended[msg.sender], "You have already checked in");
        require(verifySignature(msg.sender, _signature), "Invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;
        emit AttendeeCheckdIn(msg.sender, block.timestamp);
    }

    function verifySignature(address _attendee, bytes calldata _signature) public view returns(bool) {
        bytes32 messageHash = getMessageHash(_attendee); // 得到参与者地址的hash值
        bytes32 ethSignedMessageHash = getEthSignedHash(messageHash); // 得到加eth前缀的hash值
        return (recoverSigner(ethSignedMessageHash, _signature) == organiser);
    }

    function getMessageHash(address _attendee) public view returns(bytes32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    function getEthSignedHash(bytes32 _messageHash) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    // 恢复签名者
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns(address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // 汇编代码，直接从内存获取数据，更高效
        // add：跳过x个字节，mload：加载32字节，byte(0, mload(add(_signature, 96)))：只要第一个字节
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // EIP-155 之前，v通常是27或28,EIP-155之后（引入链ID防止重放攻击），v可能是0,1,2,3...，具体取决于链ID
        if (v < 27) v += 27; 
        // 确保标准化后的v是Ethereum标准恢复值：27 或 28
        require(v == 27 || v == 28, "Invalid Signature 'v' value");

        //Solidity 内置函数, 恢复签名者地址
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function getEventInfo() external view returns(
        string memory _eventName, 
        uint256 _eventTime, 
        uint256 _maxAttendee,
        bool _isActive
    ) {
        return (eventName, eventTime, maxAttendee, isActive);
    }

}