// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleIOU
 * @author shivam
 * @notice A simple contract to simulate a IOU (I owe you) system.
     How it works:
     - Each user has their own account with balances, they can deposit or withdraw.
     - User can lend to another user by calling lend function.
     - User can repay lent amount.
     - Contract acts as bank, where users can deposit and withdraw, lend and repay within accounts.
     - All amounts are in wei unit.
     - A mapping maintained for lent amounts.
     - Currently it's not possible to get list of addresses of borrowers or lenders.
 */
contract SimpleIOU {
    /// @notice Mapping of user address to total available balance (in wei)
    mapping (address => uint) private balances;

    /// @notice Mapping of lender address to mapping of borrower address to the amount lent.
    /// @dev lentAmounts[lender][borrower] = amount
    mapping (address => mapping (address => uint)) private lentAmounts;

    /// @notice Event emitted when a deposit is made by a user.
    /// @param from Depositor address
    /// @param amount Deposit amount value
    event Deposited(address indexed from, uint indexed amount);

    /// @notice Event emitted when a withdrawal is made by a user.
    /// @param to User address
    /// @param amount Deposit amount value
    event Withdrew(address indexed to, uint indexed amount);

    /// @notice Event emitted when a lender lends amount to borrower.
    /// @param lender Address of lender
    /// @param borrower Address of borrower
    /// @param amount Amount lent
    event Lent(address indexed lender, address indexed borrower, uint indexed amount);

    /// @notice Event emitted when a borrower repays amount to lender.
    /// @param borrower Address of borrower
    /// @param lender Address of lender
    /// @param amount Amount repaid
    event Repaid(address indexed borrower, address indexed lender, uint indexed amount);

    /// @notice Error thrown when available amount in insufficient for operation.
    /// @param requested amount requested for operation.
    /// @param available Available amount
    error InsufficientFunds(uint requested, uint available);

    /// @notice Error thrown when repayment amount exceeds borrowed amount
    /// @param lender Lender address
    /// @param amount Repayment amount attempted
    /// @param borrowed Actual borrowed amount
    error ExcessRepayment(address lender, uint amount, uint borrowed);

    /// @notice Special function that allows this contract to receive ETH.
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Fallback function to receive ETH when calldata is not empty
    fallback() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Get balance for caller
    /// @return balance Balance in wei unit
    function getBalance() external view returns (uint) {
        return balances[msg.sender];
    }

    /// @notice Get amount lent to a borrower
    /// @param _borrower Borrower address
    /// @return lentAmount Amount lent to given borrower
    function getLentAmount(address _borrower) external view returns (uint) {
        return lentAmounts[msg.sender][_borrower];
    }

    /// @notice Get amount borrowed by a lender
    /// @param _lender Lender address
    /// @return borrowedAmount Amount borrowed from given lender
    function getBorrowedAmount(address _lender) external view returns (uint) {
        return lentAmounts[_lender][msg.sender];
    }

    /// @notice Withdraw balance from contract. Balance is transferred to caller's address.
    /// @param amount Withdrawal amount in wei unit.
    /// @custom:error InsufficientFunds when `amount` is more than available balance.
    function withdraw(uint amount) external {
        // check amount
        require(amount > 0, "amount must be greater than 0");
        if (amount > balances[msg.sender]) {
            revert InsufficientFunds(amount, balances[msg.sender]);
        }

        // update state first to prevent reentrancy
        balances[msg.sender] -= amount;

        // transfer amount
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");

        // emit event
        emit Withdrew(msg.sender, amount);
    }

    /// @notice Lend given amount to borrower.
    /// @param _borrower Borrower address.
    /// @param amount Lend amount.
    /// @custom:error InsufficientFunds when `amount` is more than available balance.
    function lend(address _borrower, uint amount) external {
        // check amount
        require(amount > 0, "amount must be greater than 0");
        if (amount > balances[msg.sender]) {
            revert InsufficientFunds(amount, balances[msg.sender]);
        }

        // update states
        balances[msg.sender] -= amount;
        balances[_borrower] += amount;
        lentAmounts[msg.sender][_borrower] += amount;

        // emit event
        emit Lent(msg.sender, _borrower, amount);
    }

    /// @notice Repay given amount to lender.
    /// @param _lender Lender address.
    /// @param amount Repayment amount.
    /// @custom:error InsufficientFunds when `amount` is more than available balance.
    /// @custom:error ExcessRepayment when `amount` is more than borrowed by lender's address.
    function repay(address _lender, uint amount) external {
        // check amount
        require(amount > 0, "amount must be greater than 0");
        if (amount > balances[msg.sender]) {
            revert InsufficientFunds(amount, balances[msg.sender]);
        }
        if (amount > lentAmounts[_lender][msg.sender]) {
            revert ExcessRepayment(_lender, amount, lentAmounts[_lender][msg.sender]);
        }

        // update states
        balances[msg.sender] -= amount;
        balances[_lender] += amount;
        lentAmounts[_lender][msg.sender] -= amount;

        // emit event
        emit Repaid(msg.sender, _lender, amount);
    }
}