//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Build the entire financial system --- lending, borrowing,saving, trading and so on.
    // Deposit ETH into a pool;
    // Lock up collateral to access loans;
    // Borrow ETH based on that collateral;
    // Repay loans with interest;
    // Withdraw funds when they're done.


contract SimpleLending{
    mapping(address=>uint256) public depositBalances; // user's address=>ETH deposited in the  pool
    mapping(address=>uint256) public borrowBalances; // user's address=> amount  of ETH borrowed from the pool
    mapping(address=>uint256) public collateralBalances;// user's address=> amount of ETH provided as collateral

    uint256 public interestRateBasispoints=500;// Interest rate: 1 basis point=0.01%, 500 basis points=5%
    // The variable determines how much someone can borrow based on the value of their collateral.
    // This means users can only borrow up to 75% of the ETH they lock in as collateral.
    // The reason of not 100% is that token price volatility exists.
    uint256 public collateralFactorBasisPoints=7500;// 7500 basis points=75%
    

    mapping(address=>uint256) public lastInterestAccrualTimestamp;// Record the last time we calculated interest for each user: user's address=>interest

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user,uint256 amount);
    event Borrow(address indexed user,uint256 amount);
    event Repay(address indexed user,uint256 amount); // Triggered when a user sends ETH back to repay their loan.
    event CollateralDeposited(address indexed user,uint256 amount); // Emitted when a user locks ETH as collateral.
    event CollateralWithdrawn(address indexed user,uint256 amount); // Emitted when a user safely withdraws their collateral.

    function deposit() external payable{
        require(msg.value>0,"Must deposit a positive amount");
        depositBalances[msg.sender]+=msg.value;
        emit Deposit(msg.sender,msg.value);
    }

    function withdraw(uint256 amount) external{
        require(amount>0,"Must withdraw a positive amount");
        require(depositBalances[msg.sender]>=amount,"Insufficient balance");
        depositBalances[msg.sender]-=amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender,amount);

    }

    // If user wants to take a loan, user needs to put something down as collateral.
    function depositCollateral() external payable{
        require(msg.value>0,"Must deposit a positive amount as collateral");
        collateralBalances[msg.sender]+=msg.value;
        emit CollateralDeposited(msg.sender,msg.value);

    }

    function withdrawCollateral(uint256 amount) external{
        require(amount>0,"Must withdraw a positive amount");
        require(collateralBalances[msg.sender]>=amount,"Insufficient collateral");
        uint256 borrowedAmount=calculateInterestAccrued(msg.sender);
        uint256 requiredCollateral=(borrowedAmount*10000)/collateralFactorBasisPoints;

        require(collateralBalances[msg.sender]-amount>=requiredCollateral,"Withdrawl would break collateral ratio");
        collateralBalances[msg.sender]-=amount;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender,amount);
    }

    // Borrow ETH from the lending pool based on how much collateral they have locked up.
    function borrow(uint256 amount) external{
        require(amount>0,"Must borrow a positive amount");
        require(address(this).balance>=amount,"Not enough liquidity in the pool");
        
        uint256 maxBorrowAmount=(collateralBalances[msg.sender]*collateralFactorBasisPoints)/10000;
        uint256 currentDebt=calculateInterestAccrued(msg.sender);

        require(currentDebt+amount<=maxBorrowAmount,"Exceeds allowed borrow amount");
        borrowBalances[msg.sender]=currentDebt+amount;
        lastInterestAccrualTimestamp[msg.sender]=block.timestamp;

        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender,amount);
    }

    function repay() external payable{
        require(msg.value>0,"Must repay a positive amount");

        uint256 currentDebt=calculateInterestAccrued(msg.sender);
        require(currentDebt>0,"No debt to repay");

        uint256 amountToRepay=msg.value;
        if(amountToRepay>currentDebt){
            amountToRepay=currentDebt;
            payable(msg.sender).transfer(msg.value-currentDebt);
        }

        borrowBalances[msg.sender]=currentDebt-amountToRepay;
        lastInterestAccrualTimestamp[msg.sender]=block.timestamp;

        emit Repay(msg.sender,amountToRepay);

    }

    // Interest calculation.
    // Use this function to calculate interest on demand only when it's needed.
    function calculateInterestAccrued(address user) public view returns(uint256){
        if(borrowBalances[user]==0){
            return 0;
        }

        uint256 timeElapsed=block.timestamp-lastInterestAccrualTimestamp[user];
        uint256 interest=(borrowBalances[user]*interestRateBasispoints*timeElapsed)/(1000*365 days);

        return borrowBalances[user]+interest;
    }

    function getMaxBorrowAmount(address user) external view returns(uint256){
        return (collateralBalances[user]*collateralFactorBasisPoints)/10000;

    }

    function getTotalLiquidity() external view returns (uint256){
        return address(this).balance;

    }
}