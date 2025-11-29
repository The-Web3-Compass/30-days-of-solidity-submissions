// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthePiggyBank{
    /*
    - 加入小组（需获得批准）
    - 存钱
    - 查看余额
    - 甚至在需要时提取资金
    */
    address public bankManager;//负责管理组内成员加入退出，可能只写了加入

    address[] members;//成员组
    mapping(address => bool) public isMember;//判断是否是成员，用于权限控制
    mapping(address => uint) public balance;//成员存钱余额
    
    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        isMember[bankManager]=true;
    }

    modifier OnlyManager(){
        require(msg.sender==bankManager, "Only Manager perform this action!");
        _;
    }

    modifier OnlyMembers(){
        require(isMember[msg.sender], "Only Manager perform this action!");
        _;
    }

    function AddMembers(address _members) public OnlyManager{
        require(_members!= address(0), "Invalid address!");
        require(!isMember[_members], "Already a member!");
        members.push(_members);
        isMember[_members] = true;
    }


    function deposit() public payable OnlyMembers{
        require(msg.value > 0, "Invaild amount!");
        balance[msg.sender] += msg.value;
    }
    
    
    function withdraw(uint256 _amount) external OnlyMembers{
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount, "Insufficient balance");

        // Effects：先更新状态
        balance[msg.sender] -= _amount;

        // Interactions：再外部转账
        (bool ok, ) = payable(msg.sender).call{value: _amount}("");
        require(ok, "ETH transfer failed");
    }
}