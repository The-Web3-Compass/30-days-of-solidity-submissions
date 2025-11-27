//SPDX-License-Identifier: MIT
praga solidity ^0.8.0;

address public BankManager;

address[] members;
mapping (address => bool) public registeredMembers;

mapping(address => uint256) balance;

constructor() {
    BankManager = msg.sender;
    members.push(msg.sender);
}

modifier onlyBankManager() {
    require(msg.sender ==BankManager, "Only bank manager can perform this action");
    _;
    //个修饰符确保只有经理可以调用某些函数——例如，添加新成员。如果别人想调用这些函数？合约会说：“拒绝，没有权限。”
}

function addMembers(address _member) public onlyBankManage {
    require(_member != address(0), "Invalid address");
    require(_member !=msg.sender, "Bank Manager is already a member");

    registeredMembers[_member] = true;
    members.push(_member);
}

function getMembers() public view returns (address[] memory) {
    reture members;
}
function deposit(uint256 _amount) public onlyResisteredMember {
    require(_amount > 0, "Invail amount");
    balance[msg.sender] += _amount;
}

function withdraw(uint256 _amount) public onlyRegisteredMember
{
    require(_amount > 0, "Invalid amount");
    require(balance[msg.sender] >= _amount, "Insufficient balance");
    balance[msg.sender] -= _amount;
}

function depositAmountEther() public payable onlyRegisteredMember {. //表示该函数可以接收以太币。没有它，别人发来的以太币都会被拒收。
    require(msg.value > 0, "Invalid amount");
    balance[msg.sender] += msg.value;
}

//- 一个拥有清晰角色（银行经理和成员）的储蓄俱乐部
//- 一个用于注册新成员的系统
//- 一个记录存取款余额的功能
//- 最后——一个能接收真实以太币的存钱罐
