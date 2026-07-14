// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU_V2 {
    address public owner;

    // 朋友注册系统
    mapping(address => bool) public registeredFriends;
    address[] public friendList;

    // 余额与债务记录
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts; // debtor -> creditor -> amount

    // 分组功能
    struct Group {
        string name;
        address[] members;
    }
    mapping(uint256 => Group) public groups;
    uint256 public groupCount;

    // 🪶 事件日志
    event FriendAdded(address indexed newFriend);
    event Deposit(address indexed user, uint256 amount);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtPaid(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtForgiven(address indexed creditor, address indexed debtor, uint256 amount);
    event GroupCreated(uint256 indexed groupId, string name);
    event GroupMemberAdded(uint256 indexed groupId, address indexed member);

    constructor() {
        owner = msg.sender;
        registeredFriends[msg.sender] = true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(registeredFriends[msg.sender], "You are not registered");
        _;
    }

    // ========== 好友注册 ==========
    function addFriend(address _friend) public onlyOwner {
        require(_friend != address(0), "Invalid address");
        require(!registeredFriends[_friend], "Friend already registered");

        registeredFriends[_friend] = true;
        friendList.push(_friend);

        emit FriendAdded(_friend);
    }

    function getFriends() public view returns (address[] memory) {
        return friendList;
    }

    // ========== 钱包存取 ==========
    function depositIntoWallet() public payable onlyRegistered {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) public onlyRegistered {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    // ========== 借贷核心 ==========
    // 记录债务
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(registeredFriends[_debtor], "Debtor not registered");
        require(_amount > 0, "Amount must be greater than 0");

        debts[_debtor][msg.sender] += _amount;

        emit DebtRecorded(_debtor, msg.sender, _amount);
    }

    // 偿还债务
    function payDebt(address _creditor, uint256 _amount) public onlyRegistered {
        require(_creditor != address(0), "Invalid address");
        require(registeredFriends[_creditor], "Creditor not registered");
        require(_amount > 0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount too high");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;

        emit DebtPaid(msg.sender, _creditor, _amount);
    }

    // 债务减免（Debt Forgiveness）
    function forgiveDebt(address _debtor, uint256 _amount) public onlyRegistered {
        require(_debtor != address(0), "Invalid address");
        require(debts[_debtor][msg.sender] >= _amount, "Not enough debt to forgive");

        debts[_debtor][msg.sender] -= _amount;

        emit DebtForgiven(msg.sender, _debtor, _amount);
    }

    // ========== 分组管理 ==========
    function createGroup(string memory _name) public onlyOwner {
        require(bytes(_name).length > 0, "Group name required");
        groupCount++;
        groups[groupCount].name = _name;

        emit GroupCreated(groupCount, _name);
    }

    function addMemberToGroup(uint256 _groupId, address _member) public onlyOwner {
        require(_groupId > 0 && _groupId <= groupCount, "Invalid group ID");
        require(registeredFriends[_member], "Member not registered");

        groups[_groupId].members.push(_member);

        emit GroupMemberAdded(_groupId, _member);
    }

    function getGroupMembers(uint256 _groupId) public view returns (address[] memory) {
        require(_groupId > 0 && _groupId <= groupCount, "Invalid group ID");
        return groups[_groupId].members;
    }

    // ========== 查看功能 ==========
    function checkBalance() public view onlyRegistered returns (uint256) {
        return balances[msg.sender];
    }

    function getDebt(address debtor, address creditor) public view returns (uint256) {
        return debts[debtor][creditor];
    }

    receive() external payable {}
}