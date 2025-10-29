//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EventEntry {
    string public eventName;     //活动的名称
    address public organizer;     //活动组织者的钱包地址
    uint256 public eventDate;     //活动的举行时间，以 Unix 时间戳 表示（即秒数）
    uint256 public maxAttendees;     //活动的最大参与人数
    uint256 public attendeeCount;     //当前已签到的人数统计
    bool public isEventActive;     //活动是否正在开放签到

    //记录哪些地址已经签到
    mapping(address => bool) public hasAttended;

    event EventCreated(string name, uint256 date, uint256 maxAttendees);     //合约部署（活动创建）时触发
    event AttendeeCheckedIn(address attendee, uint256 timestamp);     //每当有人签到成功时触发
    event EventStatusChanged(bool isActive);     //主办方更改活动状态（启用/暂停）时触发

    //设置活动的初始信息
    constructor(string memory _eventName, uint256 _eventDate_unix, uint256 _maxAttendees) {
        eventName = _eventName;     //保存活动名称
        eventDate = _eventDate_unix;     //设置活动的举行时间（Unix 时间戳）
        maxAttendees = _maxAttendees;     //限制最大签到人数
        organizer = msg.sender;     //将部署者的钱包设为主办方地址，以后所有验证都以此地址为准
        isEventActive = true;     //默认活动启动时为开启状态

        //在链上广播创建事件的日志，方便前端展示或记录
        emit EventCreated(_eventName, _eventDate_unix, _maxAttendees);
    }

    //函数修饰符，用于限制函数访问权限
    modifier onlyOrganizer() {

        //只有 msg.sender（调用者）等于 organizer 时，函数才会继续执行
        require(msg.sender == organizer, "Only the event organizer can call this function");
        _;
    }
    
    //切换活动状态
    //只有主办方能调用（因为用了 onlyOrganizer 修饰符）
    //用来手动暂停或重新开放活动签到
    //状态更改后会发出 EventStatusChanged 事件
    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    //生成消息哈希（Message Hash）
    //生成每个参与者的唯一哈希值，用于签名验证
    function getMessageHash(address _attendee) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    //生成以太坊标准签名哈
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    //签名验证（核心逻辑）
    //1.生成原始消息哈希：messageHash = keccak256(contract + eventName + attendee)
    function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {

        //2.转换为以太坊签名格式，包含标准前缀
        bytes32 messageHash = getMessageHash(_attendee);

        //3.恢复签名者地址，调用 recoverSigner() 获取签名者是谁
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        //4.验证是否为主办方，如果恢复出的地址与 organizer 相同，则签名有效
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;
    }

    //从签名中恢复签名者地址
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        //签名长度检查，以太坊标准签名长度为 65 字节，不符则拒绝
        require(_signature.length == 65, "Invalid signature length");

        //分解签名数据
        bytes32 r;     //r：前 32 字节
        bytes32 s;     //s：中间 32 字节
        uint8 v;     //v：最后 1 字节（恢复参数）
        
        //汇编语言
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        //调整 v 值：某些钱包返回 0 或 1，需要转换为以太坊标准的 27 或 28
        if (v < 27) {
            v += 27;
        }

        //验证 v 的合法性：确保 v 只可能是 27 或 28
        require(v == 27 || v == 28, "Invalid signature 'v' value");

        //恢复签名者地址：调用内置函数 ecrecover()，返回签名者的地址
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    //签到函数（核心入口）
    function checkIn(bytes memory _signature) external {

        //活动是否处于开启状态？若被暂停，则拒绝签到
        require(isEventActive, "Event is not active");

        //检查当前时间是否在活动结束后 24 小时内，超时则拒绝签到
        require(block.timestamp <= eventDate + 1 days, "Event has ended");

        //防止重复签到
        require(!hasAttended[msg.sender], "Attendee has already checked in");

        //达到最大人数后拒绝新签到
        require(attendeeCount < maxAttendees, "Maximum attendees reached");

        //核心验证：1.该签名确实由主办方签发 2.签名对应的地址为当前调用者 3.签名对应的是当前活动
        require(verifySignature(msg.sender, _signature), "Invalid signature");

        //标记该地址为已签到
        hasAttended[msg.sender] = true;

        //签到人数 +1
        attendeeCount++;

        //触发链上事件，记录签到成功时间
        emit AttendeeCheckedIn(msg.sender, block.timestamp);
    }
}
