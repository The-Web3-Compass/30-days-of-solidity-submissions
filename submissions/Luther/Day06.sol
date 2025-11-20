//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherPiggyBank{     //声明一个...的合约，用以实现“以太坊存钱罐”

//应该有一个拥有特定权限的银行经理
//应该有一个包含所有已注册会员的数组，以及一个映射，用于映射他们是否已注册
//一个包含余额的映射
    address public bankManager;     //定义一个公开量，用来记录谁是银行管理员（即合约的拥有者）
    address[] members;     //定义一个数组，保存所有注册成员的地址
    mapping(address => bool) public registeredMembers;     //保存每个地址是否已经注册成为成员
    mapping(address => uint256) balance;     //保存每个成员当前在合约中的余额

//在合约部署时，把部署者设置为银行管理员，并且自动加入成员列表
    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }

//定义一个权限控制修饰符，确保只有管理员能执行特定函数
    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

//定义一个权限修饰符，用于限制只有注册人员才能执行某些函数
modifier onlyRegisteredMember() {
    require(registeredMembers[msg.sender], "Member not registered");
    _;
}

function addMembers(address _member)public onlyBankManager{     //定一个函数，让银行管理员可以添加新成员
    require(_member != address(0), "Invalid address");     //检查地址是否有效，否则退回并弹出“”
    require(_member != msg.sender, "Bank Manager is already a member");     //防止管理员重复把自己注册成成员，否则退回并弹出“”
    require(!registeredMembers[_member], "Member already registered");     //确保该成员没注册过，否则退回并弹出“”
    registeredMembers[_member] = true;     //将该成员标记为“已注册”
    members.push(_member);     //把新成员地址加入成员列表数组中
}

//让任何人可以查看当前所有注册成员的地址，view：只读取，不修改状态
function getMembers() public view returns(address[] memory){
    return members;
}

//允许注册成员向合约中存入ETH，并记录余额
function depositAmountEther() public payable onlyRegisteredMember{
    require(msg.value> 0, "Invalid amount");
    balance[msg.sender] = balance[msg.sender]+msg.value;
}

//允许注册成员从自己账户中提取一定金额
function withdrawAmount(uint _amount) public onlyRegisteredMember{
    require(_amount > 0, "Invalid amount");
    require(balance[msg.sender] >= _amount, "Insufficient balance");
    balance[msg.sender] = balance[msg.sender] - _amount;
    
}

//让任何人查询指定成员的余额
function getBalance(address _member) public view returns (uint256){
    require(_member != address(0), "Invalid address");
    return balance[_member];
}

}