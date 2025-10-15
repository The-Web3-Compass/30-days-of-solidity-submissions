// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthBank {
    address public bankManage; // 金库管理者
    address [] members; // 组成员
    mapping(address => bool) public registeredMember; // 追踪成员是否授权
    mapping(address => uint256) balanceMember; // 追踪成员的余额

    constructor(){
        bankManage = msg.sender;
        members.push(msg.sender);
    }

    // 管理员授权
    modifier onlyBankManage(){
        require(msg.sender == bankManage, "only bank manage can perform this action");
        _;
    }
    // 用户授权
    modifier onlyRegisteredMember(){
        require(registeredMember[msg.sender], "Member is not registered");
        _;
    }
    // 添加组员
    function addMerber(address _user) public onlyBankManage{
        require(_user != address(0), "Invalid address");
        require(_user != msg.sender, "Bank Manager is already a member");
        require(!registeredMember[_user], "Member already registered");

        members.push(_user);
        registeredMember[_user] = true;
    }
    // 存钱
    function bepositbalance(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        balanceMember[msg.sender] += _amount;
    }
    // 取钱
    function withdrawbalance(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");
        require(_amount <= balanceMember[msg.sender], "Insufficient balance");
        balanceMember[msg.sender] -= _amount;
    }
    // 查看组成员以及余额
    function getMerber() public view returns(address [] memory){
        return members;
    }
    function getbalance(address _user) public view returns(uint256){
        require(_user != address(0),"Invalid address");
        return balanceMember[_user];
    }
    // 尝试存入eth
    function depositEth() public payable onlyRegisteredMember{
        require(msg.value >0, "Invalid amount");
        balanceMember[msg.sender] += msg.value;
    }
}