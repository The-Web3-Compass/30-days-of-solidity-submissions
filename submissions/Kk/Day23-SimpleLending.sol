// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleLending {
    mapping(address => uint256) public depositBalances;//checking account balance
    mapping(address => uint256) public borrowBalances;//how much you owe
    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    uint256 public interestRateBasisPoints = 500;//bps  
    uint256 public collateralFactorBasisPoints = 7500;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    function deposit() external payable{
        require(msg.value > 0, "Must deposit a positive amount");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 _amount) external{
        require(_amount > 0, "Must withdraw a positive amount");
        require(depositBalances[msg.sender] >= _amount,"Insufficient balance");
        depositBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);//Can we use ".call"?
        //(bool success, ) = payable(msg.sender).call{value: amount}("");
        //require(success, "Transfer failed");
        emit Withdraw(msg.sender, _amount);
    }
    //view function, query for interests
    function calculateInterestAccrued(address _user) public view returns (uint256){
        if (borrowBalances[_user] == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[_user];
        uint256 interest = (borrowBalances[_user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);
        return borrowBalances[_user] + interest;
    }

    function depositCollateral() external payable{
        require(msg.value > 0, "Must deposit a positive amount as collateral");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    function withdrawCollateral(uint256 _amount) external{
        require(_amount > 0, "Must withdraw a positive amount");
        require(collateralBalances[msg.sender] >= _amount, "Insufficient collateral");

        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;

        require(collateralBalances[msg.sender] - _amount >= requiredCollateral, "Withdrawal would break collateral ratio");

        collateralBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit CollateralWithdrawn(msg.sender, _amount);
    }

    function borrow(uint256 _amount) external{
        require(_amount > 0, "Must borrow a positive amount");
        require(address(this).balance >= _amount, "Not enough liquidity in the pool");
        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterestAccrued(msg.sender);

        require(currentDebt + _amount <= maxBorrowAmount, "Exceeds allowed borrow amount");

        borrowBalances[msg.sender] = currentDebt + _amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(_amount);
        emit Borrow(msg.sender, _amount);
    }
    
    function repay() external payable {
        require(msg.value > 0, "Must repay a positive amount");

        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt > 0, "No debt to repay");

        uint256 amountToRepay = msg.value;
        if (amountToRepay > currentDebt) {
            amountToRepay = currentDebt;
            payable(msg.sender).transfer(msg.value - currentDebt); // Refund the extra
        }
        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        emit Repay(msg.sender, amountToRepay);
    }

    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }

    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }
}
