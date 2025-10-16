// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;
    address[] friends;
    mapping(address => bool) public isFriend;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public debtRecordBook;

    constructor(){
        owner = msg.sender;
        friends.push(msg.sender);
        isFriend[msg.sender] = true;
    }

    modifier OnlyOwner(){
        require(owner == msg.sender,"Not the owner!!");
        _;
    }

    modifier OnlyFriend(){
        require(isFriend[msg.sender],"Not friend!!");
        _;
    }

    function addFriend(address _addr) public OnlyOwner{
        require(!isFriend[_addr],"Already in...");
        friends.push(_addr);
        isFriend[_addr] = true;
    }

    function recordDebt(address _debtor,uint256 _amount) public OnlyFriend{
        require(isFriend[_debtor],"Permissio Denied");
        debtRecordBook[_debtor][msg.sender] += _amount; //_debtor own msg.sender _amount dollar
    }

    function checkMyDebt() public view OnlyFriend returns(address[] memory, uint256[] memory) {
    uint256 len = friends.length;
    uint256[] memory debts = new uint256[](len);

    for (uint256 i = 0; i < len; i++)
        debts[i] = debtRecordBook[msg.sender][friends[i]];

        return (friends, debts);
    }

    //存入合约中
    function deposit(uint256 _amount) public payable OnlyFriend{
        require(_amount > 0,"send more");
        balance[msg.sender] += _amount;
    }

    //从合约中取钱  
    function withdraw(uint256 _amount) public OnlyFriend{
        require(_amount > 0, "invalid amount");
        require(balance[msg.sender] > _amount, "balance insufficient!!");

        balance[msg.sender] -= _amount;
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success,"tx failed!");
    }

    //直接从合约把钱转到user地址
    function payDebtDirect(address payable _to,uint256 _amount)public OnlyFriend{
        require(isFriend[_to],"Not friend,addr invalid");
        require(_amount > 0,"send more");
        require(balance[msg.sender] > _amount, "balance insufficient!!");

        balance[msg.sender] -= _amount;
        (bool success,) = _to.call{value: _amount}("");
        require(success,"tx failed!!");
    }
    //保存在合约里，等user自己weithdraw
    function payDebt(address _to)public payable OnlyFriend{
        require(isFriend[_to],"Not friend,addr invalid");
        require(msg.value > 0,"send more");
        require(balance[msg.sender] > msg.value, "balance insufficient!!");

        balance[msg.sender] -= msg.value;
        balance[_to] += msg.value;   
        
    
    }

    function getFriendsList() public view returns(address [] memory){
        return friends;
    }

}