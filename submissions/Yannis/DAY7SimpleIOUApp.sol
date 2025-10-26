//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU{
    address public owner;
    
    mapping(address => bool) public registeredFriends;
    address[] public friendList;
    
    mapping(address => uint256) public balances;
    
    mapping(address => mapping(address => uint256)) public debts; 
    
    event FriendAdded(address indexed friend);
    event Deposited(address indexed who, uint256 amount);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event PaidFromWallet(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtForgiven(address indexed debtor, address indexed creditor, uint256 amount);
    event EtherTransferred(address indexed from, address indexed to, uint256 amount);
    event EtherTransferredViaCall(address indexed from, address indexed to, uint256 amount, bool success);
    event Withdrawn(address indexed who, uint256 amount);
    event GroupCreated(uint indexed groupId, address indexed creator);
    event MemberAddedToGroup(uint indexed groupId, address indexed member);

    uint public groupCount;
    mapping(uint => address[]) private groups;           
    mapping(address => uint[]) private memberGroups;     

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
        emit FriendAdded(msg.sender); 
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }
    
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");
        
        registeredFriends[_friend] = true;
        friendList.push(_friend);

        emit FriendAdded(_friend); 
    }
    
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value); 
    }
    
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Address not registered");
        require(_amount > 0, "Amount must be greater than 0");
        
        debts[_debtor][msg.sender] += _amount;

        emit DebtRecorded(_debtor, msg.sender, _amount); 
    }
    
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount incorrect");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;

        emit PaidFromWallet(msg.sender, _creditor, _amount); 
    }
    
    function transferEther(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        balances[_to]+=_amount;

        emit EtherTransferred(msg.sender, _to, _amount); 
    }
    
    function transferEtherViaCall(address payable _to, uint256 _amount) public onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(registeredFriends[_to], "Recipient not registered");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = _to.call{value: _amount}("");
        balances[_to]+=_amount;
        emit EtherTransferredViaCall(msg.sender, _to, _amount, success); 
        require(success, "Transfer failed");
    }
    
    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, _amount); 
    }
    
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }

    function forgiveDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Debtor not registered");
        uint256 owe = debts[_debtor][msg.sender];
        require(owe > 0, "No debt to forgive");
        require(_amount > 0 && _amount <= owe, "Invalid forgive amount");

        debts[_debtor][msg.sender] = owe - _amount;
        emit DebtForgiven(_debtor, msg.sender, _amount);
    }

    function createGroup(address[] calldata _members) external onlyRegistered returns (uint) {
        require(_members.length > 0, "Group must have at least one member");

        uint gid = groupCount + 1;
        groupCount = gid;

        for (uint i = 0; i < _members.length; i++) {
            address m = _members[i];
            require(m != address(0), "Invalid member");
            
            require(registeredFriends[m], "Member not registered");
            groups[gid].push(m);
            memberGroups[m].push(gid);
            emit MemberAddedToGroup(gid, m);
        }

        emit GroupCreated(gid, msg.sender);
        return gid;
    }

    function getGroupMembers(uint _groupId) external view returns (address[] memory) {
        return groups[_groupId];
    }

    function getMemberGroups(address _member) external view returns (uint[] memory) {
        return memberGroups[_member];
    }

    function getDebt(address _debtor, address _creditor) external view returns (uint256) {
        return debts[_debtor][_creditor];
    }
}
