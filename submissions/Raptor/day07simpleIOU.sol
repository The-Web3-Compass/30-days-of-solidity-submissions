// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract simpleIOU{
    address public owner;
    mapping(address => bool)public isRegistered;
    address[] public memberList;
    mapping (address => uint256) public balances; 
    mapping(address => mapping(address => uint256)) public debts;//qian'zhai'de,zhai'zhu,jin'e



    constructor(){
        owner = msg.sender;
        isRegistered[owner] = true;
        memberList.push(msg.sender);
    }


    modifier onlyOwner() {
        require (msg.sender == owner,"Ur not the owner!");
        _;
    }

    modifier onlyRegistered() {
        require (isRegistered[msg.sender],"Ur not registered!");
        _;
    }

    function addMember(address _address) public onlyOwner {
        require (_address != address(0),"Invalid address!");
        require (!isRegistered[_address],"Already registered!");  
        isRegistered[_address] = true;
        memberList.push(_address);
    }

    function depositIntoWallet () public payable onlyRegistered {
        require(msg.value > 0,"No money get away!");
        balances[msg.sender] += msg.value;
    }

    function recordDebt (address _debtor,uint256 _amount) public onlyRegistered {
        require (_debtor != address(0),"Invalid address!");
        require(isRegistered[_debtor],"Address is not registered!");
        require(_amount > 0,"Invalid amount!");
        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(address _creditor,uint256 _amount) public onlyRegistered {
        require(_creditor != address(0),"Invalid address!");
        require(isRegistered[_creditor],"Address is not registered!");
        require((balances[msg.sender] >= _amount) && (_amount > 0),"Invalid amount!");
        require(balances[msg.sender] >= _amount,"Insufficient balance!");
        require(debts[msg.sender][_creditor] >= _amount,"You are not owed that much!");
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }

    function transferEther(address payable _to,uint256 _amount) public onlyRegistered{
        require(_to != address(0),"Invalid address!");
        require(isRegistered[_to],"Address is not registered!");
        require(balances[msg.sender] >= _amount,"Insufficient balance!");
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);

    }

    function transferEtherViaCall(address payable _to,uint256 _amount) public onlyRegistered{
        require(_to != address(0),"Invalid address!");
        require(isRegistered[_to],"Address is not registered!");
        require(balances[msg.sender] >= _amount,"Insufficient balance!");
        balances[msg.sender] -= _amount;
        (bool success,) = _to.call{value: _amount}(""); // call
        balances[_to] += _amount; 
        require(success,"Transfer failed!"); 
        
    }

    function withdraw(uint256 _amount)public onlyRegistered{
        require(balances[msg.sender] >= _amount,"Insufficient balance!");
        balances[msg.sender] -= _amount;

        (bool success,) = payable(msg.sender).call{value:_amount}("");
        require(success,"Withdraw failed!");
    }

    function checkBalance()public view   onlyRegistered returns(uint256){
        return balances[msg.sender];
    }

}