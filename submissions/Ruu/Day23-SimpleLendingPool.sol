//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SimpleLending{

    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public borrowBalances;
    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public lastInterestAccuralTimestamp;

    uint256 public interestRateBasisPoints = 500;
    uint256 public collateralFactorBasisPoints = 7500;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    function deposit() external payable{
        require(msg.value > 0, "Eth value should be more than 0");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external{
        require(amount > 0, "Must withdraw more than 0");
        require(depositBalances[msg.sender] >= amount, "Insufficient balance");
        depositBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function calculateInterestAccured(address user) public view returns(uint256){
        if(borrowBalances[user] == 0){return 0;}

        uint256 timeElapsed = block.timestamp - lastInterestAccuralTimestamp[user];
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed)/(10000 * 365 days);
        return borrowBalances[user] + interest;
    }

    function depositCollateral() external payable{
        require(msg.value > 0, "Eth value should be more than 0");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    function withdrawCollateral(uint256 amount) external{
        require(amount > 0, "Must withdraw more than 0");
        require(collateralBalances[msg.sender] >= amount, "Insufficient balance");
        uint256 borrowedAmount = calculateInterestAccured(msg.sender);
        uint256 requiredCollateral = (borrowedAmount *10000)/collateralFactorBasisPoints;

        require(collateralBalances[msg.sender] - amount >= requiredCollateral, "Withdrawal not possible it would break collateral ratio");
        collateralBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    function borrow(uint256 amount) external{
        require(amount > 0, "Must borrow more than 0");
        require(address(this).balance >= amount, "Not enough liquidity in the pool");
        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints)/10000;
        uint256 currentDebt = calculateInterestAccured(msg.sender);
        require(currentDebt + amount <= maxBorrowAmount, "Exceeds allowed borrow amount");
        borrowBalances[msg.sender] = currentDebt + amount;
        lastInterestAccuralTimestamp[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
    }

    function repay() external payable{
        require(msg.value > 0, "Must repay a positive amount");
        uint256 currentDebt = calculateInterestAccured(msg.sender);
        require(currentDebt > 0, "No debt to repay");
        uint256 amountToRepay = msg.value;

        if(amountToRepay > currentDebt){
            amountToRepay = currentDebt;
            payable(msg.sender).transfer(msg.value - currentDebt);
        }

        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccuralTimestamp[msg.sender] = block.timestamp;
        emit Repay(msg.sender, amountToRepay);
    }

    function getMaxBorrowAmount(address user) external view returns(uint256){
        return (collateralBalances[user] * collateralFactorBasisPoints)/10000;
    }

    function getTotalLiquidity() external view returns(uint256){
        return address(this).balance;
    }
    
}
