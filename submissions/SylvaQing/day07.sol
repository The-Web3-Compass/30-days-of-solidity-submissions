// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SimpleIOU{

    address public owner;
    address[] public  friendList;
    mapping(address=>bool) isRged;
    mapping(address=>uint256) balances;
    mapping(address=>mapping (address=>uint256)) debts;

    constructor(){
        owner=msg.sender;
        isRged[msg.sender]=true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }
    modifier onlyRged(){
        require(isRged[msg.sender],"You are not registered");
        _;
    }
    //注册好友
    function addFriend(address _friend) public onlyOwner{
        require(!isRged[_friend],"This address is already registered");
        isRged[_friend]=true;
        friendList.push(_friend);
    }
    //查询余额
    function checkBalance(address _friend) public view returns(uint256){
        return balances[_friend];
    }

    //充值到钱包
    function depositIntoWallet() public payable onlyRged {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }
    //记录欠款
    function recordDebt(address _debtor, uint256 _amount) public onlyRged {
        require(_debtor != address(0), "Invalid address");
        require(isRged[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        
        debts[_debtor][msg.sender] += _amount;
    }
    //钱包还款
    function payFromWallet(address _creditor, uint256 _amount) public onlyRged {
        require(_creditor != address(0), "Invalid address");
        require(isRged[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // 更新余额和欠账
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
    }
    
    //直接转账
    function transferEther(address payable _to, uint256 _amount) public onlyRged {
        require(_to != address(0), "Invalid address");
        require(isRged[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to]+=_amount;
    }
    //call方法
        function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRged {
        require(_to != address(0), "Invalid address");
        require(isRged[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = _to.call{value: _amount}("");
        balances[_to]+=_amount;
        require(success, "Transfer failed");
    }
    
    //撤回
    function withdraw(uint256 _amount) public onlyRged {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }
    //检查
        function checkBalance() public view onlyRged returns (uint256) {
        return balances[msg.sender];
    }
}