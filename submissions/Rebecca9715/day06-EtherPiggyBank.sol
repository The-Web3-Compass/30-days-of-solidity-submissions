// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalPiggyBank {
    mapping(address => uint256) public balances;

    // 定一个掌管银行的管理者，只有管理者可以增加成员
    address public bankManager;
    // 一个members的清单，并记录每一个账户是否为注册账户
    address[] members;
    mapping(address => bool) public registeredMembers;
    // 记录每个人账户的余额
    mapping(address => uint256) balance;

    //银行管理者自动为启动部署的用户，且将其加入members列表 
    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
        // 在此基础上要增加银行管理员为注册用户
        registeredMembers[msg.sender] = true;
    }

    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }
    // 只有银行管理员可以增加用户
    function addMembers(address _member)public onlyBankManager{
        // 需要为有效的地址
        // 不为银行管理员（同时在此场景下银行管理员无法更换）
        // 需要不为当前注册会员
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){
        return members;
    }

    // deposit amount 
    function depositAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        balance[msg.sender] = balance[msg.sender]+_amount;
   
    }

    // 真实存款
    function depositAmountEther() public payable onlyRegisteredMember{  
        require(msg.value > 0, "Invalid amount");
        balance[msg.sender] = balance[msg.sender]+msg.value;
   
    }
    // 取款
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] = balance[msg.sender]-_amount;
   
    }
    // 查看余额
    function getBalance(address _member) public view returns (uint256){
        require(_member != address(0), "Invalid address");
        return balance[_member];
    } 
    
    // 查询当前用户地址
    function getSender() public view returns (address){
        return msg.sender;
    }
}

// Day06
// 1. 部署，并且自动会录入当前启动部署的address为bankManager
// 2. 点击addMembers，可以增加成员，只有bankManager可以增加成员
// 3. 点击getMembers，可以查看当前成员列表
// 4. 点击depositAmount，可以存钱，只有注册用户可以存钱
// 5. 点击withdrawAmount，可以取钱，只有注册用户可以取钱
// 6. 点击getBalance，可以查看当前账户余额
// 7. 点击getSender，可以查看当前账户地址
// 8. 真实ETH测试，将depositEther设置为payable，remix中的按钮会变红
// 9. 在相应的账户之下，可以输入金额，点击depositEther，可以存入真实的ETH
