// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IOUContract {
    // 事件声明，用于记录存款、债务记录和债务结算
    event Deposited(address indexed user, uint256 amount);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtSettled(address indexed debtor, address indexed creditor, uint256 amount);
constructor() payable {
    // 可以在这里执行一些初始化操作
}
    // 存储每个用户的余额
    mapping(address => uint256) public balances;

    // 存储债务关系，格式为 balances[debtor][creditor] = amount
    mapping(address => mapping(address => uint256)) public debts;

    // 存款函数，允许用户向合约存入ETH
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // 记录债务关系，允许用户记录谁欠谁多少钱
    function recordDebt(address _creditor, uint256 _amount) public {
        require(_creditor != address(0), "Invalid creditor address");
        require(_amount > 0, "Debt amount must be greater than zero");
        require(balances[msg.sender] >= _amount, "Insufficient balance to record this debt");

        debts[msg.sender][_creditor] += _amount;
        balances[msg.sender] -= _amount;
        emit DebtRecorded(msg.sender, _creditor, _amount);
    }

    // 结算债务，允许债务人向债权人转账来结算债务
    function settleDebt(address _creditor) public {
        require(_creditor != address(0), "Invalid creditor address");
        require(debts[msg.sender][_creditor] > 0, "No debt to settle");

        uint256 amountToSettle = debts[msg.sender][_creditor];
        require(balances[msg.sender] >= amountToSettle, "Insufficient balance to settle debt");

        balances[msg.sender] -= amountToSettle;
        balances[_creditor] += amountToSettle;
        debts[msg.sender][_creditor] = 0;

        emit DebtSettled(msg.sender, _creditor, amountToSettle);
    }

    // 获取用户余额
    function getBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }

    // 获取债务信息
    function getDebt(address _debtor, address _creditor) public view returns (uint256) {
        return debts[_debtor][_creditor];
    }
}