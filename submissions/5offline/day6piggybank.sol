//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

//涉及到交易了 piggybank一般指存钱罐
//声明变量：管理者，存钱罐成员，注册会员，他们的账户
contract Etherpiggybank{
    address public bankmanager;
    address[]members;
    mapping(address=>bool)public registermembers;
    //bool值，是member就变成了true 默认false
    mapping(address=>uint256)balance;

    constructor(){
        bankmanager=msg.sender;
        members.push(msg.sender);
        //把自己推到成员的组里

    }
    modifier onlybankmanager(){
        require(msg.sender==bankmanager, "only bank manager can perform this action.");
        _;
    }
    modifier onlyregistermember(){
        require(registermembers[msg.sender],"member is not registered.");
        _;
    }
    //两个修正符

    function addmembers(address _member)public onlybankmanager{
        require(_member !=address(0),"invalid address");
        require(_member !=msg.sender,"bank manager is already a member");
        require(!registermembers[_member],"member already registered");
        //！=是不等于 ！xx是非xx

        registermembers[_member]=true;
        members.push(_member);

    }
    function getmembers()public view returns(address[]memory){
        return members;
        //得到成员列表
    }

    function deposit(uint256 _amount)public  onlyregistermember{
        require(_amount>0,"invalid amount");
        balance[msg.sender] +=_amount;
        //先存款，amount的钱加入balance

    }
        function depositeth()public payable onlyregistermember{
        require(msg.value >0,"invalid amount");
        balance[msg.sender] += msg.value;
        //这个是真的在交易存款，payable和msg.value绑定

    }
    function getbalance(address _member)public view returns(uint256){

        require(_member !=address(0) ,"invalid address");
        return balance[_member];

        //得到账户数据
    }

    function withdraw(uint256 _amount) public onlyregistermember{
        require(_amount>0, "invalid amount");
        require(balance[msg.sender]>= _amount,"insufficient balance");
        balance[msg.sender]-=_amount;

//取款操作
    }


}
