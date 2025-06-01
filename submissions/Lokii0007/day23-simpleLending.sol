// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SimpleLending {
    mapping(address => uint256) depositBalances;
    mapping(address => uint256) borrowBalances;
    mapping(address => uint256) collateralDeposited;
    mapping(address => uint256) lastInterestAccuralTimestamp;

    uint public interestRateBAsisPoints = 500;
    uint public collateralFactorBasisPoints = 7500;
    
    event Deposit(address indexed user, uint indexed amount);
    event Withdraw(address indexed user, uint indexed amount);
    event Borrow(address indexed user, uint indexed amount);
    event Repay(address indexed user, uint indexed amount);
    event CollateralDeposited(address indexed user, uint indexed amount);
    event CollateralWithdraw(address indexed user, uint indexed amount);

    function deposit() external payable {
        require(msg.value > 0, "deposit amount shoulder be greater than 0");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount) external {
        require(_amount > 0, "withdraw amount shoulder be greater than 0");
        require( depositBalances[msg.sender] >= _amount, "withdraw amount shoulder be greater than your balance");
        depositBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit Withdraw(msg.sender, _amount);
    }

    function getInterestAccured(address _user) public view returns(uint) {
        if(depositBalances[_user] == 0){
            return 0;
        }

        uint timeElapsed = block.timestamp - lastInterestAccuralTimestamp[_user];
        uint interest = (borrowBalances[_user] * interestRateBAsisPoints * timeElapsed)/(10000 * 365 days);
        return borrowBalances[_user] + interest;
    }

    function depositCollateral() external payable {
        require(msg.value > 0, "deposit amount shoulder be greater than 0");
        collateralDeposited[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    function withdrawCollateral(uint _amount) external {
        require(_amount > 0, "withdraw amount shoulder be greater than 0");
        require( collateralDeposited[msg.sender] >= _amount, "withdraw amount shoulder be greater than your balance");
        
        uint amountBorrowed = getInterestAccured(msg.sender);
        uint requiredCollateral = (10000 * amountBorrowed )/collateralFactorBasisPoints;

        require(collateralDeposited[msg.sender] - _amount >= requiredCollateral, "insufficient collateral");
        collateralDeposited[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit CollateralWithdraw(msg.sender, _amount);
    }

    function borrow(uint _amount) external {
        require(_amount > 0, "withdraw amount shoulder be greater than 0");
        require( address(this).balance > _amount, "not enough liquidity in the pool");
        
        uint maxBorrowAmount = (collateralDeposited[msg.sender] * collateralFactorBasisPoints)/10000;
        uint currentDebt = getInterestAccured(msg.sender);

        require(currentDebt + _amount <= maxBorrowAmount, "not enough collateral balance");
        borrowBalances[msg.sender] += _amount + currentDebt;
        lastInterestAccuralTimestamp[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(_amount);

        emit CollateralWithdraw(msg.sender, _amount);
    }

    function repay() external payable {
        require(msg.value > 0, "repay amount shoulder be greater than 0");
        uint currentDebt = getInterestAccured(msg.sender);
        
        require(currentDebt > 0 , "no debt to repay");
        uint amountToRepay = msg.value;
        
        if(amountToRepay >= currentDebt){
            amountToRepay = currentDebt;
            payable(msg.sender).transfer(msg.value - currentDebt);
        }

        borrowBalances[msg.sender] -= amountToRepay;
        lastInterestAccuralTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, amountToRepay);
    }

    function getMaxBorrowAmount(address _user) external view returns(uint){
        uint maxBorrowAmount = (collateralDeposited[_user] * collateralFactorBasisPoints)/10000;
        return maxBorrowAmount;
    }

    function getPoolLiquiduty() external view returns(uint){
        return address(this).balance;
    }
}