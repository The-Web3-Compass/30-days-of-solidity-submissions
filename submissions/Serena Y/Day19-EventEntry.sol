// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventEntry {
    string public eventName;//事件名字
    address public organizer;//组织者
    uint256 public eventDate;//事件时间
    uint256 public maxAttendees;//最大参与人数
    uint256 public attendeeCount;//参与人数
    bool public isEventActive;//时间是否有效

    mapping(address => bool) public hasAttended;//映射 地址对应是否参加

    event EventCreated(string name, uint256 date, uint256 maxAttendees);//事件生成 名字 日期 最大参与人数
    event AttendeeCheckedIn(address attendee, uint256 timestamp);//参与人签到，事件戳
    event EventStatusChanged(bool isActive);//事件状态是否改变

    constructor(string memory _eventName, uint256 _eventDate_unix, uint256 _maxAttendees) {
        eventName = _eventName;//事件名字
        eventDate = _eventDate_unix;//事件日期
        maxAttendees = _maxAttendees;//最大参与人数
        organizer = msg.sender;//组织者
        isEventActive = true;//事件有效

        emit EventCreated(_eventName, _eventDate_unix, _maxAttendees);//广播，事件成功生成
    }

    modifier onlyOrganizer(){
        require(msg.sender==organizer,"Only the event organizer can call this function");
        _;
    }

    //设置事件状态

    function setEventStatus(bool _isActive) external onlyOrganizer{
        isEventActive=_isActive;
        emit EventStatusChanged(isEventActive);
    }

    function getMessageHash(address _attendee) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this),eventName,_attendee));
        //将合约地址，事件名字，参与者三个信息打包，然后生成哈希值
    }

    //以太坊签名消息哈希

       function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));//将原始哈希值用前缀再重新包装成以太坊签名消息哈希值
    }

    //签名验证

    function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
    bytes32 messageHash = getMessageHash(_attendee);//生成基本消息哈希值
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);//转换为以太坊签名格式
    return recoverSigner(ethSignedMessageHash, _signature) == organizer;//恢复签名者，如果匹配则签名有效，如果没有签名无效
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        require(_signature.length == 65, "Invalid signature length");//检查签名长度 所有以太坊签名的长度都是 65 字节 ——不多也不少。

        bytes32 r;//32字节
        bytes32 s;//32字节
        uint8 v;//1字节

        assembly {
            r := mload(add(_signature, 32))//_signature + 32 到 _signature + 64
            s := mload(add(_signature, 64))//_signature + 64 到 _signature + 96
            v := byte(0, mload(add(_signature, 96)))//位于 _signature + 96 的第一个字节
            //byte(i, x): 从 32 字节的字 x 中提取第 i 个字节。i=0 是最高位字节
            //mload(p): 从内存地址 p 处读取 32 字节 数据
        }

        if (v < 27) {//修复v值
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");//满足v值是27或者28

        return ecrecover(_ethSignedMessageHash, v, r, s);//返回签名者地址 我们现在知道是谁签署了这条消息
    }

    //checkIn – Web3 活动的前门

    function checkIn(bytes memory _signature) external {
        require(isEventActive, "Event is not active"); //需要检查活动是否有效
        require(block.timestamp <= eventDate + 1 days, "Event has ended");//活动事件是否满足要求
        require(!hasAttended[msg.sender], "Attendee has already checked in");//是不是已经check in了
        require(attendeeCount < maxAttendees, "Maximum attendees reached");//参与者人数是不是小于最大人数
        require(verifySignature(msg.sender, _signature), "Invalid signature");//检查签名

        hasAttended[msg.sender] = true;//设置成check in
        attendeeCount++;//参与者数量+1

        emit AttendeeCheckedIn(msg.sender, block.timestamp);//公告，参与者checkin
    }


}