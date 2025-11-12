//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleLending {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public borrowAmounts;
    mapping(address => uint256) public collaterals; // 抵押资产

    uint256 public interestRateBasisPoints = 500; // 5%年利率
    uint256 public collateralFactorBasisPoints = 7500; // 75%抵押系数

    mapping(address => uint256) public lastInterestAccrualTimestamp; // 最近更新债务的时间

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount should be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdraw amount should be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function depositCollateral() external payable {
        require(msg.value > 0, "Collateral amount should be greater than 0");
        collaterals[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "Withdraw amount should be greater than 0");
        uint256 _currentDebt = currentDebt(msg.sender);
        uint256 requiredCollateral = _currentDebt * 10000 / collateralFactorBasisPoints;
        require(amount <= collaterals[msg.sender] - requiredCollateral, "Insufficient collateral");

        collaterals[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        emit CollateralWithdrawn(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "Borrow amount should be greater than 0");
        require(address(this).balance > amount, "Insufficient liquidity");
        uint256 _currentDebt = currentDebt(msg.sender);
        require(amount + _currentDebt <= maxBorrowAmount(msg.sender), "Borrow amount exceeds maximum allowed");

        borrowAmounts[msg.sender] = _currentDebt + amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(amount);

        emit Borrow(msg.sender, amount);
    }

    function repay() external payable {
        require(msg.value > 0, "Repay amount should be greater than 0");
        uint256 _currentDebt = currentDebt(msg.sender);
        require(_currentDebt > 0, "No debt to repay");

        uint256 _repayAmount = msg.value;
        if (_repayAmount > _currentDebt) {
            _repayAmount = _currentDebt;
            payable(msg.sender).transfer(msg.value - _repayAmount);
        }
        borrowAmounts[msg.sender] = _currentDebt - _repayAmount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, _repayAmount);
    }
    
    // 加上利率之后的债务
    function currentDebt(address user) public view returns(uint256) {
        require(address(0) != user, "Invalid address");

        if (borrowAmounts[user] == 0) return 0;

        uint256 timePassed = block.timestamp - lastInterestAccrualTimestamp[user];
        uint256 interest = borrowAmounts[user] * interestRateBasisPoints * timePassed / (10000 * 365 days);

        return borrowAmounts[user] + interest;
    }

    function maxBorrowAmount(address user) public view returns(uint256) {
        require(address(0) != user, "Invalid address");

        return (collaterals[user] * collateralFactorBasisPoints / 10000);
    }

    function getTotalLiquidity() public view returns(uint256) {
        return address(this).balance;
    }

}