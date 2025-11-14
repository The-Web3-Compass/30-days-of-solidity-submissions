//SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;

contract EtherPiggyBank{// 谁是负责人？每个团体都需要——负责吸收新成员并维持秩序。所以我们引入了银行经理bank manager
 
    address public bankManager;//这就是部署合约的人。拥有管理员权限——只有她可以批准新成员加入俱乐部
    address[] members;// 谁是成员？我们需要一种方式来追踪谁有权使用存钱罐。members，一个数组，用来保存所有加入的人。
    mapping(address =>bool) public registeredMembers;//registeredMembers：一个映射，可以让我们快速检查某人是否已被批准
    mapping(address =>uint256) balance;//我们需要知道每位成员在这段时间里一共存了多少钱/存钱罐的核心功能。它会记录每位成员的余额。
    
    constructor(){
        bankManager = msg.sender;//把合约当前调用者的地址（部署时就是部署者）设置为 bankManager。比喻：开馆仪式上，拿钥匙的人被任命为“馆长”。
        members.push(msg.sender); //把同一个地址（当前调用者）加入到成员数组 ⁠members⁠ 的末尾，成为第一个成员。比喻：馆长也在现场办了第一张会员卡，被记录进会员名册。
    }//这两行确保系统一启动就“有人负责、有人在册”，避免出现“无管理员/空成员列表”的异常状态。
    
    
    modifier onlyBankManager(){//我们要明确每个人能做什么，就需要用到**修饰符（modifiers）它是一小段可以重复使用的逻辑，用来保护你的函数。
        require(msg.sender == bankManager, "Only bank manager can perform this action");
    _;//这个修饰符确保只有经理可以调用某些函数——例如，添加新成员。如果别人想调用这些函数？合约会说：“拒绝，没有权限。
}
    modifier onlyRegisteredMember() {//
    require(registeredMembers[msg.sender], "Member not registered");
    _;//这个修饰符确保只有已被正式添加入列表的成员可以存钱或取钱。
}

 function addMembers(address _member) public onlyBankManager {//只有馆长能在前台给别人办卡，普通会员和路人不行（权限控制）
    require(_member != address(0), "Invalid address");//不能给“空地址”办卡，避免无效账户进入系统
    require(_member != msg.sender, "Bank Manager is already a member");//馆长自己已经在首批入会名单里，不能重复给自己办卡
    require(!registeredMembers[_member], "Member already registered");//不能重复发卡，避免一人多张、数据脏乱

    registeredMembers[_member] = true;//在“门禁名单”里把该地址标记为已登记，以后可存取款
    members.push(_member);//把他加入“会员名册”数组，列表展示时能看到此人
}
 //这个函数：确保存入金额大于零；将该金额加到你的余额中
 
 function withdraw(uint256 _amount) public onlyRegisteredMember { //检票口：public onlyRegisteredMember，只有持“会员卡”的人能到取款窗口办理，路人不可操作（身份校验）
    require(_amount > 0, "Invalid amount");//取款必须是正数，别把“取0或负数”当操作提交（有效金额）
    require(balance[msg.sender] >= _amount, "Insufficient balance");//柜台先看你的账本余额是否足够，不允许透支（不能欠账）
    balance[msg.sender] -= _amount;//在账本上把你的余额减去这次取出的数额，相当于“更新内账”（账本扣款）
}
function depositAmountEther() public payable onlyRegisteredMember {//
    require(msg.value > 0, "Invalid amount");
    balance[msg.sender] += msg.value;
}

  }
    