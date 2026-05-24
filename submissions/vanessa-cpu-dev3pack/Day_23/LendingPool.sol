// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleLending {
    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public borrowBalances;
    mapping(address => uint256) public collateralBalances;
    uint256 public interestRateBasisPoints = 500; // 5% Interest
    uint256 public collateralFactorBasisPoints = 7500; // 75% LTV (Loan to Value)
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    function deposit() external payable {
        depositBalances[msg.sender] += msg.value;
    }

    function depositCollateral() external payable {
        collateralBalances[msg.sender] += msg.value;
    }

    function calculateInterestAccrued(address user) public view returns (uint256) {
        if (borrowBalances[user] == 0) return 0;
        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);
        return borrowBalances[user] + interest;
    }

    function borrow(uint256 amount) external {
        uint256 maxBorrow = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt + amount <= maxBorrow, "Exceeds limit");
        borrowBalances[msg.sender] = currentDebt + amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(amount);
    }

    function repay() external payable {
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        borrowBalances[msg.sender] = currentDebt - msg.value;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
    }
}