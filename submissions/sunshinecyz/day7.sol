// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner ;
    mapping(address => bool) public registedFriend;
    address[] public FriendList; 

    mapping(address => uint256) public balances;
    //债务关系 
    mapping(address => mapping(address => uint256)) public debts;
    
    constructor() {
        owner = msg.sender;
        registedFriend[owner] = true;
        FriendList.push(msg.sender);
    }

    modifier  onlyOwner(){
        require(msg.sender == owner,"only owner can perform");
        _;
    }

    modifier  onlyRegister(){
        require(registedFriend[msg.sender]==true,"only register can perform ");
        _;
    }

    //添加朋友
    function addFriend(address _friend) public onlyOwner{
        require(_friend != address(0),"invalid address");
        require(registedFriend[_friend] == false,"friend has already register");
        FriendList.push(_friend);
        registedFriend[_friend] = true;
    }

    //存钱
    function depositIntoWallet() public payable onlyRegister{
        require(msg.value > 0 ,"invalid amount");
        balances[msg.sender] += msg.value;
    }

    //记录债务
    function recordDebt(address _debt,uint256 _amount) public onlyRegister{
        require(_debt != address(0),"invalid address");
        require(registedFriend[_debt] == true ,"invalid registers");
        require(_amount > 0 ,"invalid amount");
        debts[_debt][msg.sender] += _amount;
    }

    //还债
    function payFromWallet(address _creditor , uint256 _amount) public  onlyRegister{
        require(_creditor != address(0),"invalid address");
        require(registedFriend[_creditor],"invalid register");
        require(_amount > 0 ,"invalid amount");
        require(_amount <= debts[msg.sender][_creditor] ,"insufficient  debt amount ");
        require(_amount <= balances[_creditor],"insufficient balances");
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
        balances[msg.sender] -= _amount; 
    }

    //通过transfer函数转帐
    function transferEther(address payable  _friend,uint256 _amount) public payable onlyRegister{
        require(_friend != address(0),"invalid address");
        require(registedFriend[_friend], "invalid register");
        require(_amount<= balances[msg.sender] , "invalid amount");

        balances[msg.sender] -= _amount;
        _friend.transfer(_amount);
        balances[_friend] += _amount;
    }

    //通过call函数转帐
    function transferEthViaCall(address payable _friend , uint256 _amount) public   onlyRegister{
        require(_friend != address(0), "invalid address");
        require(registedFriend[_friend],"invalid register");
        require(balances[msg.sender] >= _amount,"insufficent amount");
        balances[msg.sender] -= _amount;
        (bool success, ) = _friend.call{value:_amount}("");
        balances[_friend] += _amount;
        require(success,"Transfer failed");
    }
    
    //用户提款
    function withdraw(uint256 _amount) public onlyRegister{
        require(_amount > 0 , "invalid amount");
        require(_amount <= balances[msg.sender], "insufficient amount");

        balances[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value:_amount}("");
        require(success,"withdraw failed ");

    }

    function checkBalance() public view onlyRegister returns(uint256){
        return  balances[msg.sender];
    }

}