// SPDX-License-Identifier: MIT

//把我当作小白解答下面的问题
pragma solidity ^0.8.0;

contract piggyBank{
    /*
    1. 声明manager，member，balance[]
    2. constructor：manager是谁，manager设置为member
    3. 添加一个modifier进行权限过滤
    4. 添加用户：一个array，仅限owner录入address；注意 1.地址有效 2.manager没有重复添加自己 3.这个member并不是已经存在的
    5. show Members
    5.增加balance
    6.提取balance
    */
    address bankManager;
    address[] members;
    mapping (address =>bool) registeredMembers; //双重验证非常重要，请解释一下为什么在这里再增加bool双重验证？很多加密合约似乎都会加上bool验证，为什么？
    mapping (address => uint256) balance;

    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    modifier bankManagerOnly(){
        require (msg.sender == bankManager, "Only bank manager can perform this action!");
        _;
    }

    modifier memberOnly(){
        require (registeredMembers[msg.sender], "Member not registered.");
        _;
    }

    function addMember(address _member) public bankManagerOnly{
        require (_member != address(0),"Invalid address.");
        require (_member != msg.sender, "bank manager cannot register again.");
        require (!registeredMembers[_member], "Member already registered.");//没有录入过的mapping值registeredMembers[]为什么可以直接这样验证？因为默认是0吗？
        registeredMembers[_member] = true; //不要忘记bool
        members.push(_member);
    }

    function getMembers() public view returns(address[] memory){//为什么我在这里加上memberOnly的modifier会报错？
        return members;
    }

    function deposit(uint256 _amount) public memberOnly{ //为什么要写uint256，写uint不行吗？为什么非要规定大小？
        //1.确保有权限 2.添加大于0的值 3.加到余额里面
        require (_amount > 0, "Invalid amount.");
        balance[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) public memberOnly{
        require (_amount > 0, "Invalid amount.");
        require (balance[msg.sender] >= _amount, "Insufficient balance.");//注意在取钱的时候检查余额
        balance[msg.sender] -= _amount;
    }

    function depositAmountEther() public payable memberOnly{
        require (msg.value > 0, "Invalid amount");
        balance[msg.sender] += msg.value;
    }


    //对于两个modifier是否功能是不重叠的？比如如果加上了memberOnly就代表bankManager无法使用这个函数？以及为什么没有给manager添加registeredMember的bool值？
}