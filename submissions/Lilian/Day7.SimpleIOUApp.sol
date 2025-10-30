// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleIOU{
    address public owner;
    mapping (address=>bool)public registeredfriends;
    address[] public friendlist;

    mapping (address=>uint256)public balances;
    mapping (address=>mapping (address=>uint256))public debts;

    constructor(){
        owner=msg.sender;
        registeredfriends[msg.sender]=true;
        friendlist.push(msg.sender);
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner can perform this action");
        -;
    }
    modifier onlyregister(){
        require(registeredfriends[msg.sender],"You are not registered");
        _;
    }
    function addfriend(address_friend)public onlyOwner{
        require(_friend!=address（0），"Invalid address");
        require(!registeredfriends[_friend],"Friend already registered");

        registeredfriends[_friend]=true;
        friendlist.push(_friend);
    }
    function depoistintoWallet()public payable onlyregister{
        require(msg.value>0,"must end ETH");
        balances[msg.sender]+=msg.sender;
    }
    function recordDebt(address _Debter,uint256 _amount)public onlyregister{
        require(_debter !=address(0), "Invalid address");
        require(registeredfriends[_debter],"Address has not registered");
        require(_amount>0,"Amount must be greater than 0");

        debts.[_Debter][msg.sender]+=_amount;
    }
    function payfromwallet(address_creditor,uint256 _amount)public onlyregister{
        require(_creditor !=address(0),"Invalid adress");
        require(registeredfriends[_creditor],"Creditor has not registered");
        require(_amount>0,"amount must be greater than 0");
        require(debts[msg.sender][_creditor]>_=amount,"Debt amount incorrect");
        require(balance[msg.sender]>=_amount,"Insufficent balance");

        balances[msg.sender]-=_amount;
        balances[_creditor]+=_amount;
        debts[msg.sender][_creditor]-=_amount;
    }
    function transferEther (address payable _to,uint256 _amount)public onlyregister{
        require(_to !=address(0), "Invalid Address");
        require(registeredfriends[_to],"Recipent not registered");
        require(balances[msg.sender]>=_amount,"Insufficent balance");
        balances[msg.sender]-=_amount;
        _to.transfer(_amount);
        balances[_to]+=_amount;
    }
    function transferEtherviacall(address payable_to,uint256 _amount)public onlyregister{
    require(_to != address(0), "Invalid address");
    require(registeredFriends[_to], "Recipient not registered");
    require(balances[msg.sender] >= _amount, "Insufficient balance");

    balances[msg.sender] -= _amount;
    
    (bool.success,)=_to.call{value:_amount}("")
    balances[_to]+=_amount;
    require(success,"Transfer failed");
    }
    function withdrw (uint256 _amount)public onlyregister{
        require(balances[msg.sender]>=_amount,"Insufficent balance");

        balances[msg.sender]-=_amount;

        (bool.success,)=payable (msg.sender).call{value:_amount}("");
        require(success,"withdrawal failed");
    }
    function checkbalance() public view onlyregister returns (uint256){
        return balances[msg.sender]
    }