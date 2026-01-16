// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EventEntry {
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

    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    function getMessageHash(address _attendee) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    // 生成 符合 Ethereum 签名标准的消息哈希，用于签名验证
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)); 
    } // ""这一段是EIP-191 以太坊消息签名标准的前缀，类似于写信盖章

    //判断恢复出来的签名者地址是否等于组织者地址 
    function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_attendee);// 生成原始消息哈希 绑定到用户的地址上
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);//生成符合Ethereum签名标准的最终哈希
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;// 根据签名恢复出签名者的地址
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure //表示函数 不会读取或修改合约的状态
        returns (address)
    {
        require(_signature.length == 65, "Invalid signature length");
        //数组里装了 65 字节的数据 （ECDSA 标准签名长度，检查签名是否完整）

        bytes32 r; //32 字节
        bytes32 s; //32 字节
        uint8 v;   //1 字节，恢复公钥用

        assembly {//EVM汇编语言，省gas费
            r := mload(add(_signature, 32)) //从_signature的起始位置往后偏移32个字节，再取32个字节
            s := mload(add(_signature, 64)) //从_signature的起始位置往后偏移64个字节，再取32个字节
            v := byte(0, mload(add(_signature, 96))) //只取出这 32 字节中的第一个
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");//以太坊签名验证必须是27或28

        return ecrecover(_ethSignedMessageHash, v, r, s); //一段消息的哈希，一段签名（分成 r、s、v）
    }

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