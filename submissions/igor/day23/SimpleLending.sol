  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleLending{
    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public borrowBalances;
    //抵押余额（你抵押进去的 ETH）
    mapping(address => uint256) public collateralBalances;

    uint256 public interestRateBasisPoints = 500;   // 年利率5%
    uint256 public collateralFactorBasisPoints = 7500;  // 抵押率75%
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    function deposit() external payable{
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {

        depositBalances[msg.sender] -= _amount;
        (bool success,) = payable(msg.sender).call{value:_amount}("");
        require(success,"tx failed");
        emit Withdraw(msg.sender, _amount);
    }

    function depositCollateral() external payable{
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    //取出抵押余额，但要先计算该余额是否允许
    function withdrawCollateral(uint256 _amount) external {
        uint256 borrowedAmount = calculateInterest(msg.sender);
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;

        require(collateralBalances[msg.sender] - _amount  >= requiredCollateral,
        "can not withdraw..."
        );
        collateralBalances[msg.sender] -= _amount;
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success,"");
        emit CollateralWithdrawn(msg.sender, _amount);
        
    }

    function borrow(uint256 _amount) external{
        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterest(msg.sender);

        require(currentDebt + _amount <= maxBorrowAmount,"can not");

        borrowBalances[msg.sender] += _amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success,"");
        emit Borrow(msg.sender, _amount);
    }

    function repay() external payable{
        uint256 currentDebt = calculateInterest(msg.sender);
        require(currentDebt > 0,"good boy");

        uint256 amountToRepay = msg.value;
        if (amountToRepay > currentDebt) {
            amountToRepay = currentDebt;
            payable(msg.sender).transfer(msg.value - currentDebt);
        }

        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, amountToRepay);
    }

    function calculateInterest(address _user) public view returns(uint256){
        if(borrowBalances[_user] == 0) return 0;

        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[_user];
        uint256 interest = (borrowBalances[_user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);

        return interest + borrowBalances[_user];
    }

    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }
}