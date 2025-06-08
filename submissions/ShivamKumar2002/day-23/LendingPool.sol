// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LendingPool
 * @author shivam
 * @notice This contract implements a simple lending and borrowing pool for Ether (ETH).
 * Users can deposit ETH to earn interest and borrow ETH against their deposited collateral.
 * Interest is calculated based on the number of blocks passed.
 */
contract LendingPool {

    // --- State Variables ---

    /// @notice The total amount of ETH currently pooled in the contract.
    uint256 public totalPooledETH;

    /// @notice Mapping from user address to their deposited ETH amount.
    mapping(address => uint256) public deposits;

    /// @notice Mapping from user address to their currently borrowed ETH amount (including accrued interest).
    mapping(address => uint256) public borrowedAmounts;

    /// @notice Mapping from user address to the block number of their last loan interaction (borrow or repay).
    /// Used for calculating accrued interest.
    mapping(address => uint256) public borrowStartTime;

    /// @notice The interest rate applied per block. Scaled by 1e18. A higher value represents a higher interest rate.
    uint256 public interestRatePerBlock;

    /// @notice The minimum required collateral ratio as a percentage, e.g., 150 means 150% collateral is required for the borrowed amount.
    uint256 public collateralizationRatioPercent;

    // --- Events ---

    /// @notice Emitted when a user successfully deposits ETH.
    /// @param user The address of the user who deposited.
    /// @param amount The amount of ETH deposited.
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user successfully borrows ETH.
    /// @param user The address of the user who borrowed.
    /// @param amount The amount of ETH borrowed.
    event Borrow(address indexed user, uint256 amount);

    /// @notice Emitted when a user successfully repays a loan.
    /// @param user The address of the user who repaid.
    /// @param amount The amount of ETH repaid.
    event Repay(address indexed user, uint256 amount);

    /// @notice Emitted when a user successfully withdraws deposited ETH.
    /// @param user The address of the user who withdrew.
    /// @param amount The amount of ETH withdrawn.
    event Withdraw(address indexed user, uint256 amount);

    /// @notice Emitted when interest is calculated and added to a user's borrowed amount.
    /// @param user The address of the user whose interest was accrued.
    /// @param interest The amount of interest accrued.
    event InterestAccrued(address indexed user, uint256 interest);

    // --- Constructor ---

    /**
     * @notice Initializes the LendingPool contract.
     * @param _interestRatePerBlock The interest rate to apply per block, scaled by 1e18.
     * @param _collateralizationRatioPercent The minimum required collateral ratio as a percentage (e.g., 150 for 150%).
     */
    constructor(uint256 _interestRatePerBlock, uint256 _collateralizationRatioPercent) {
        interestRatePerBlock = _interestRatePerBlock;
        collateralizationRatioPercent = _collateralizationRatioPercent;
    }

    // --- Internal helper functions ---

    /**
     * @notice Calculates the accrued interest for a user's loan since their last interaction.
     * Interest is calculated based on the borrowed amount, interest rate per block, and blocks passed.
     * @param _user The address of the user.
     * @return accruedInterest The calculated accrued interest.
     */
    function _calculateAccruedInterest(address _user) internal view returns (uint256) {
        uint256 lastInteractionBlock = borrowStartTime[_user];
        if (lastInteractionBlock == 0) {
            return 0; // No active loan or first interaction
        }
        uint256 blocksPassed = block.number - lastInteractionBlock;
        uint256 currentBorrowed = borrowedAmounts[_user];

        // Simple interest calculation: borrowedAmount * interestRatePerBlock * blocksPassed
        // Need to handle potential overflow and scaling.
        // Assuming interestRatePerBlock is scaled by 1e18 for simplicity in this example
        // Actual interest rate should be much smaller.
        // For example, if interestRatePerBlock is 1e15 (0.001 * 1e18), it's 0.1% per block
        // Interest = (currentBorrowed * interestRatePerBlock * blocksPassed) / 1e18
        uint256 accruedInterest = (currentBorrowed * interestRatePerBlock * blocksPassed) / 1e18;
        return accruedInterest;
    }

    /**
     * @notice Calculates and adds accrued interest to a user's borrowed amount and updates the borrow start time.
     * Called before processing deposit, borrow, and repay operations to ensure interest is up-to-date.
     * @param _user The address of the user.
     */
    function _updateBorrowedAmountWithInterest(address _user) internal {
        uint256 accruedInterest = _calculateAccruedInterest(_user);
        if (accruedInterest > 0) {
            borrowedAmounts[_user] += accruedInterest;
            emit InterestAccrued(_user, accruedInterest);
        }
        // Update borrowStartTime only if there is an active loan
        if (borrowedAmounts[_user] > 0) {
             borrowStartTime[_user] = block.number;
        } else {
             // If loan is fully repaid, reset borrowStartTime
             borrowStartTime[_user] = 0;
        }
    }

    // --- External functions ---

    /**
     * @notice Allows users to deposit ETH into the lending pool. The deposited ETH serves as collateral for borrowing.
     * @dev Requires the deposit amount to be greater than 0. Updates accrued interest on any outstanding loan before processing the deposit.
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // Update borrowed amount with interest before processing deposit
        _updateBorrowedAmountWithInterest(msg.sender);

        deposits[msg.sender] += msg.value;
        totalPooledETH += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to borrow ETH from the lending pool against their deposited collateral.
     * @dev Requires the borrow amount to be greater than 0 and less than or equal to the total pooled ETH.
     * Requires sufficient collateral based on the `collateralizationRatioPercent`.
     * Updates accrued interest on any outstanding loan before processing the borrow.
     * Sets the borrow start time if it's a new loan.
     * @param _amount The amount of ETH to borrow.
     */
    function borrow(uint256 _amount) external {
        require(_amount > 0, "Borrow amount must be greater than 0");
        require(_amount <= totalPooledETH, "Insufficient ETH in the pool");

        // Update borrowed amount with interest before processing borrow
        _updateBorrowedAmountWithInterest(msg.sender);

        uint256 currentBorrowedWithInterest = borrowedAmounts[msg.sender];
        uint256 currentDeposit = deposits[msg.sender];

        // Calculate max borrowable amount based on collateral
        // maxBorrowable = (currentDeposit * 100) / collateralizationRatioPercent
        uint256 maxBorrowable = (currentDeposit * 100) / collateralizationRatioPercent;

        require(currentBorrowedWithInterest + _amount <= maxBorrowable, "Insufficient collateral");

        borrowedAmounts[msg.sender] += _amount;
        totalPooledETH -= _amount;

        // Set borrow start time if it's a new loan
        if (borrowStartTime[msg.sender] == 0) {
             borrowStartTime[msg.sender] = block.number;
        }

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH transfer failed");

        emit Borrow(msg.sender, _amount);
    }

    /**
     * @notice Allows users to repay their outstanding loan and accrued interest.
     * @dev Requires the repayment amount to be greater than 0.
     * Requires an outstanding loan.
     * Updates accrued interest on the loan before processing the repayment.
     * Handles potential overpayment by rejecting the transaction.
     */
    function repay() external payable {
        require(msg.value > 0, "Repay amount must be greater than 0");

        // Update borrowed amount with interest before processing repayment
        _updateBorrowedAmountWithInterest(msg.sender);

        uint256 currentBorrowedWithInterest = borrowedAmounts[msg.sender];
        require(currentBorrowedWithInterest > 0, "No outstanding loan to repay");
        uint256 amountToRepay = msg.value;
        require(amountToRepay <= currentBorrowedWithInterest, "Overpayment");

        uint256 remainingLoan = 0;

        remainingLoan = currentBorrowedWithInterest - amountToRepay;
        
        borrowedAmounts[msg.sender] = remainingLoan;
        totalPooledETH += amountToRepay; // Return repaid amount to the pool

        // If loan is fully repaid, reset borrow start time
        if (remainingLoan == 0) {
            borrowStartTime[msg.sender] = 0;
        }

        emit Repay(msg.sender, amountToRepay);
    }

    /**
     * @notice Allows users to withdraw their deposited ETH.
     * @dev Requires the withdrawal amount to be greater than 0 and less than or equal to the user's deposit.
     * Requires the remaining deposit to meet the collateral requirements for any outstanding loan.
     * Updates accrued interest on any outstanding loan before checking collateral.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Withdraw amount must be greater than 0");
        require(_amount <= deposits[msg.sender], "Insufficient deposit amount");

        // Update borrowed amount with interest before checking collateral
        _updateBorrowedAmountWithInterest(msg.sender);

        uint256 currentBorrowedWithInterest = borrowedAmounts[msg.sender];
        uint256 currentDeposit = deposits[msg.sender];
        uint256 remainingDeposit = currentDeposit - _amount;

        // Check if remaining deposit meets collateral requirements for outstanding loan
        // remainingDeposit * 100 >= currentBorrowedWithInterest * collateralizationRatioPercent
        require(remainingDeposit * 100 >= currentBorrowedWithInterest * collateralizationRatioPercent, "Insufficient collateral remaining after withdrawal");

        deposits[msg.sender] = remainingDeposit;
        totalPooledETH -= _amount;

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH transfer failed");

        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Returns the current borrowed amount for a user, including accrued interest, and the accrued interest amount itself.
     * @param _user The address of the user.
     * @return currentLoanAmount The total outstanding loan amount including accrued interest.
     * @return accruedInterestSinceLastInteraction The amount of interest accrued since the last loan interaction.
     */
     function getUserLoanDetails(address _user) external view returns (uint256 currentLoanAmount, uint256 accruedInterestSinceLastInteraction) {
        uint256 accruedInterest = _calculateAccruedInterest(_user);
        return (borrowedAmounts[_user] + accruedInterest, accruedInterest);
    }
}