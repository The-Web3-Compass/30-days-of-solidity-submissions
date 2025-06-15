// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    address private owner; // 存钱罐地址，部署者
    mapping(address => uint256) private balances;
    mapping(address => bool) private hasDeposited;
    uint256 private totalUsers;
    uint256 private totalBalance;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only admin can call this");
        _;
    }

    modifier onlySelf(address account) {
        require(msg.sender == account, "You can only operate on your own account");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice 用户向自己的账户存款
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");

        // 新用户增加总用户数
        if (!hasDeposited[msg.sender]) {
            hasDeposited[msg.sender] = true;
            totalUsers += 1;
        }

        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
    }

    /// @notice 用户提取自己的以太币
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        totalBalance -= amount;

        payable(msg.sender).transfer(amount);
    }

    /// @notice 查询自己的账户余额
    function checkMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    /// @notice 管理员查询总存款用户数
    function getTotalUsers() external view onlyOwner returns (uint256) {
        return totalUsers;
    }

    /// @notice 管理员查询总余额
    function getTotalBalance() external view onlyOwner returns (uint256) {
        return totalBalance;
    }
}
