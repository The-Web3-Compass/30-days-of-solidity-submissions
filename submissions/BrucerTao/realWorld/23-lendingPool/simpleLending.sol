// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleLending {
    mapping(address => uint256) public depositBalances; //存款余额

    mapping(address => uint256) public borrowBalances; //用户从池中借了多少eth

    mapping(address => uint256) public collateralBalances; //用户提供的抵押物的eth数量

    uint256 public interestRateBasisPoints = 500;  //每年支付的贷款利率基点500个=5%

    uint256 public collateralFactorBasisPoints = 7500; //表示用户最多只能借他们锁定的eth的75%作为抵押品

    mapping(address => uint256) public lastInterestAccuralTimestamp;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    //用户将eth添加到借贷池
    function deposit() external payable {
        require(msg.value > 0, "must deposti a positive amount");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    //提取资金
    function withdraw(uint256 amount) external {
        require(amount > 0, "must withdraw a postition amount");
        require(depositBalances[msg.sender] >= amount, "Insufficient balance");
        depositBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function depositCollateral() external payable {
        require(msg.value > 0, "must deposit a positive amount as collateral");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    //提取你抵押的eth
    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "must withdraw a positive amount");
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral");
        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;
        require(
            collateralBalances[msg.sender] - amount >= requiredCollateral,
            "withdrawl would break collateral ratio"
        );
        collateralBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    //让用户根据抵押物数量，从借贷池中借入eth
    function borrow(uint256 amount) external {
        require(amount > 0, "must borrow a positive amount");
        require(address(this).balance >= amount, "not enough liquidity in the pool");
        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt + amount <= maxBorrowAmount, "exceed allowed borrow amount");
        borrowBalances[msg.sender] = currentDebt + amount;
        lastInterestAccuralTimestamp[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
    }

    //偿还贷款
    function repay() external payable {
        require(msg.value > 0, "must repay a positive amount");
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt > 0, "no debt to repay");
        uint256 amountToRepay = msg.value;
        if(amountToRepay > currentDebt) {
            amountToRepay = currentDebt;
            payable(msg.sender).transfer(msg.value - currentDebt);
        }
        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccuralTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, amountToRepay);
    }

    //利息计算器，在需要的时候计算
    function calculateInterestAccrued(address user) public view returns (uint256) {
        if(borrowBalances[user] == 0){
            return 0;
        }
        uint256 timeElapsed = block.timestamp - lastInterestAccuralTimestamp[user];
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);
        return borrowBalances[user] + interest;
    }

    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }

    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }

}