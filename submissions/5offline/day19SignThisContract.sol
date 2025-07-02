//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//线下签名：发给每个被邀请者一个邀请码，签到时核实邀请码
//不会存储邀请宾客名单
contract EventEntry {
    //想一些变量：做私人邀请活动需要什么
    //活动内容、谁组织、最多多少人参加、什么时候开始活动、谁已经到了、活动是否有效
    string public eventName;
    address public organizer;
    //活动组织者的 Ethereum 地址
    uint256 public eventDate;
    //Unix 时间戳表示
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    //到了的人
    bool public isEventActive;

    mapping(address => bool) public hasAttended;
    //这个人来了没

    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    //开活动的时候
    event AttendeeCheckedIn(address attendee, uint256 timestamp);
    //签到的时候，谁、几点
    event EventStatusChanged(bool isActive);
    //活动结束

    constructor(string memory _eventName, uint256 _eventDate, uint256 _maxAttendees) {
    //部署时赋值，时间是unix形式的，要去复制粘贴
    eventName = _eventName;
    eventDate = _eventDate;
    maxAttendees = _maxAttendees;
    organizer = msg.sender;
    isEventActive = true;
    //活动开始

    emit EventCreated(_eventName, _eventDate, _maxAttendees);
    //触发事件
    }
    
    modifier onlyOrganizer() {
    require(msg.sender == organizer, "Only the event organizer can call this function");
    _;
}
//权限设置

      function setEventStatus(bool _isActive) external onlyOrganizer {
      isEventActive = _isActive;
      emit EventStatusChanged(_isActive);
}
//可暂停或恢复这个活动
      function getMessageHash(address _attendee) public view returns (bytes32) {
        //每个签名给一个哈希值，获得参与者的地址然后给哈希值

        //获取一条信息对签名版本来操作，哈希编码
      return keccak256(abi.encodePacked(address(this), eventName, _attendee));
}
//get哈希，因为哈希一般是随机给的，有重复使用的危险，所以有一个系统专门的前缀来验证
  //保护性前缀 x19 n32 来把这个码保护起来     
      function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        //输入刚才得到的用户码
      return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
      //没包装的话就算哈希值对了也不能进门
}
      function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
        //邀请制的核心，怎么验证
      bytes32 messageHash = getMessageHash(_attendee);
      //重新创建组织者在链下为特定参与者签名的哈希
      bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
      //用安全的前缀包装
      return recoverSigner(ethSignedMessageHash, _signature) == organizer;}
      //还没收到信息，一会儿回来补充接收到了什么
      //提取消息签名者的地址
      function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address){
        //哪个以太坊签的过关通知
        require(_signature.length == 65, "Invalid signature length");
        //所有以太坊签名的长度均为 65 长度不对就停
        //把这些分成三大块，分别是rsv
         bytes32 r; //（32 字节）
         bytes32 s; //（32 字节）
         uint8 v; //1字节
         //能还原谁给的邀请码
         assembly {
            //取内存里找数据，前32个字节叫r
        r := mload(add(_signature, 32))
        s := mload(add(_signature, 64))
        //第64开始给32个字节 这个叫s
        v := byte(0, mload(add(_signature, 96)))
        //位置 96 的 1 个字节，叫v
        //把这些东西组装起来
    }
    if (v < 27) {
           v += 27;
           //有些钱包给的是1/0，但是以太坊希望它是 27 或 28，要操作一下
    }
     require (v == 27 || v == 28, "Invalid signature 'v' value");
     //看v对不对
    return ecrecover(_ethSignedMessageHash, v, r, s);
    //把这个值返回,返回签名者的地址 看出了是谁签了签名，回到verify那里补足整个信息
    
}
      function checkIn(bytes memory _signature) external {
        //全部的要求，先通过这些检查再继续
     require(isEventActive, "Event is not active");
     //活动在有在有效期内？
     require(block.timestamp <= eventDate + 1 days, "Event has ended");
     //活动后一天内可以签到
     require(!hasAttended[msg.sender], "Attendee has already checked in");
     //这个人签过到了
      require(attendeeCount < maxAttendees, "Maximum attendees reached");
      //人太多了 进不来了
     require(verifySignature(msg.sender, _signature), "Invalid signature");
     //确实是被邀请来的
      hasAttended[msg.sender] = true;
      attendeeCount++;
      //加人数
      emit AttendeeCheckedIn(msg.sender, block.timestamp);
}
       //用javascript来获取签名，先部署，再得到哈希值，再运行java




}








