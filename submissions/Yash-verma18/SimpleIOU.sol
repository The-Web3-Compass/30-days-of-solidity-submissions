// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIou {
    
    address public owner;
    address[] private friends;
    mapping(address => uint) public balances;
    mapping(address => bool) public isFriend;
    mapping(address => mapping(address => uint)) public owedAmount; // creditor -> debtor -> amount

    constructor() {
        owner = msg.sender;
        friends.push(msg.sender);
        isFriend[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner, "Only admin can call this function");
        _;
    }

    modifier onlyFriend() {
        require(isFriend[msg.sender], "Only friends can call this function");
        _;
    }

    function addFriend(address friend) public onlyAdmin {
        require(friend != address(0), "Invalid address");
        require(friend != owner, "Friend cannot be the owner");
        require(!isFriend[friend], "Friend already added");

        friends.push(friend);
        isFriend[friend] = true;
    }

    function registerIouMember(address friend, uint256 amount) public onlyFriend {
        require(friend != address(0), "Invalid address");
        require(friend != msg.sender, "You cannot register yourself");
        require(amount > 0, "Amount must be greater than 0");
        require(isFriend[friend], "Friend not added");
        owedAmount[msg.sender][friend] += amount;
    }

    function deposit() payable public onlyFriend {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }

    function settleDebt(address to, uint256 amount) public onlyFriend {
        require(to != address(0), "Invalid address");
        require(isFriend[to], "Friend not added");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(owedAmount[to][msg.sender] >= amount, "Insufficient owed amount");

        balances[msg.sender] -= amount;
        balances[to] += amount;
        owedAmount[to][msg.sender] -= amount;
    }

    function withdraw(uint256 amount) public onlyFriend {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function checkBalance() public view onlyFriend returns (uint256) {
        return balances[msg.sender];
    }

    function getAllDebts() public view onlyFriend returns (address[] memory, uint256[] memory) {
        uint count = 0;
        for (uint i = 0; i < friends.length; i++) {
            if (owedAmount[friends[i]][msg.sender] > 0) {
                count++;
            }
        }

        address[] memory creditors = new address[](count);
        uint256[] memory debts = new uint256[](count);

        uint index = 0;
        for (uint i = 0; i < friends.length; i++) {
            uint256 debt = owedAmount[friends[i]][msg.sender];
            if (debt > 0) {
                creditors[index] = friends[i];
                debts[index] = debt;
                index++;
            }
        }

        return (creditors, debts);
    }

    function settleAllMyDebts() public onlyFriend {
        (address[] memory creditors, uint256[] memory debts) = getAllDebts();
        uint256 totalDebt = 0;
        for (uint i = 0; i < debts.length; i++) {
            totalDebt += debts[i];
        }

        require(balances[msg.sender] >= totalDebt, "Insufficient balance to clear all debts");

        for (uint i = 0; i < creditors.length; i++) {
            address creditor = creditors[i];
            uint256 debt = debts[i];
            balances[creditor] += debt;
            owedAmount[creditor][msg.sender] -= debt;
            balances[msg.sender] -= debt;
        }
    }
}
