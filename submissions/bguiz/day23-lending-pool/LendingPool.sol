// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title LendingPool
 * @dev Build a system for lending and borrowing digital assets.
 * You'll learn how to calculate interest and manage collateral, demonstrating core DeFi concepts.
 * It's like a digital bank for crypto, showing how to create lending and borrowing platforms.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 23
 */
contract LendingPool {
    // NOTE depositing cryptocurrency only, not ERC20 tokens
    mapping(address => uint256) public lends;
    mapping(address => uint256) public borrows;
    mapping(address => uint256) public collaterals;
    mapping(address => uint256) public interestTimestamps;

    uint256 public interestRate = 200; // 200 basis points = 2%
    uint256 public collateralFactor = 2500; // 2500 basis points = 25%

    modifier moreThanZero(uint256 amount) {
        require(amount > 0, "amount must be more than zero");
        _;
    }

    constructor() {
    }

    function addDeposit() public payable moreThanZero(msg.value) {
        lends[msg.sender] += msg.value;
    }

    function addCollateral() public payable moreThanZero(msg.value) {
        collaterals[msg.sender] += msg.value;
    }

    function withdrawDeposit(uint256 amount) public moreThanZero(amount) {
        require(lends[msg.sender] >= amount, "cannot withdraw deposit more than deposited balance");
        lends[msg.sender] -= amount;
        (bool transferSuccess,) = (payable(msg.sender)).call{ value: amount }("");
        require(transferSuccess, "transfer failed");
    }

    function withdrawCollateral(uint256 amount) public moreThanZero(amount) {
        require(collaterals[msg.sender] >= amount, "cannot withdraw collateral more than collateralised balance");
        collaterals[msg.sender] -= amount;
        (bool transferSuccess,) = (payable(msg.sender)).call{ value: amount }("");
        require(transferSuccess, "transfer failed");
    }

    receive() external payable {
        addDeposit();
    }

    function borrow(uint256 amount) public moreThanZero(amount) {
        require(address(this).balance > amount, "insufficient liquidity");
        uint256 maxAmount = collaterals[msg.sender] * collateralFactor / 10_000;
        require(amount <= maxAmount, "exceeds max allowed amount");
        uint256 debt = calcInterest(msg.sender) + borrows[msg.sender];
        require(amount + debt <= maxAmount, "with debt, exceeds max allowed amount");
        borrows[msg.sender] = debt + amount;
        interestTimestamps[msg.sender] = block.timestamp;
        (bool transferSuccess,) = (payable(msg.sender)).call{ value: amount }("");
        require(transferSuccess, "transfer failed");
    }

    function repay() external payable moreThanZero(msg.value) {
        uint256 debt = calcInterest(msg.sender) + borrows[msg.sender];
        require(debt > 0, "no debt");
        
        uint256 repayAmount = msg.value;
        if (repayAmount > debt) {
            // send back exccess
            repayAmount = debt;
            (bool transferSuccess,) = (payable(msg.sender)).call{ value: msg.value - repayAmount }("");
            require(transferSuccess, "transfer failed");
        }

        borrows[msg.sender] = debt - repayAmount;
        interestTimestamps[msg.sender] = block.timestamp;
    }

    function calcInterest(address user) public view returns(uint256) {
        uint256 borrowedAmount = borrows[user];
        if (borrowedAmount == 0) {
            return 0;
        }
        uint256 duration = block.timestamp - interestTimestamps[user];
        uint256 interestAccrued = borrowedAmount * interestRate * duration * 365 / 10_000;
        return interestAccrued;
    }
}
