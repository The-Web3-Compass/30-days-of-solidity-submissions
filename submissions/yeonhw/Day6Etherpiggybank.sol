// SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract Etherpiggybank{
    address public bankManager; //负责人
    address[] members; //加入的会员
    mapping(address =>bool) public registeredMembers; //判断是否是会员  应该还需要对应的代码来去判断将bool值变为1
    mapping(address => uint256) balance; //每个会员对应存储了多少钱

    constructor(){
        bankManager = msg.sender;  //部署合约的人作为负责人
        members.push(msg.sender);  //将部署合约的人加入到会员名单中
    }

    modifier onlyBankManager(){
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember(){
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }

    //添加新会员
    function addMembers(address _member) public onlyBankManager{  //还是不太明白什么时候加_什么时候加memory呢？
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");  //这个函数只有bankmanager可以调用，因此msg.sender一定是对应部署合约的人的地址
        require(!registeredMembers[_member], "Member already registered");

        registeredMembers[_member] = true;
        members.push(_member);
    }

    //存款
    function deposit(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");  //要求存入的钱大于0
        balance[msg.sender] += _amount; //将该用户存入的钱放入它对应的映射中
    }

    //取款
    function withdraw(uint256 _amount) public onlyRegisteredMember{
        require(_amount > 0, "Invalid amount");  //要求提款大于0
        require(balance[msg.sender] >= _amount, "Insufficient balance");  //要求会员账户中的钱款大于提款数
        require(balance[msg.sender] >= _amount);  //从该用户账户中扣除提款数
    }

    //将真实的以太币存入存钱罐
    function depositAmountEther() public payable onlyRegisteredMember{  //payable表示允许该函数接受以太币
        require(msg.value > 0, "Invalid amount");  // msg.value保存用户发送的以太币数量
        balance[msg.sender] += msg.value;
    }

}
