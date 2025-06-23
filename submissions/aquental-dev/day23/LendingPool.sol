// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LendingPool is ReentrancyGuard {
    using SafeMath for uint256;

    // Supported ERC20 token for lending/borrowing
    IERC20 public token;
    // Annual interest rate (in basis points, 100 = 1%)
    uint256 public constant INTEREST_RATE = 500; // 5% annual
    // Loan-to-Value ratio (in basis points, 8000 = 80%)
    uint256 public constant LTV_RATIO = 8000; // 80%
    // Liquidation threshold (in basis points, 8500 = 85%)
    uint256 public constant LIQUIDATION_THRESHOLD = 8500; // 85%
    // Seconds in a year for interest calculations
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // User deposits (lender's supplied assets)
    mapping(address => uint256) public deposits;
    // User borrows (borrower's loans)
    mapping(address => uint256) public borrows;
    // Collateral balances (in native token, e.g., ETH)
    mapping(address => uint256) public collaterals;
    // Timestamp of last borrow or interest update
    mapping(address => uint256) public lastUpdateTime;
    // Accumulated interest per borrower
    mapping(address => uint256) public accruedInterest;

    // Event emitted when a user deposits tokens
    event Deposited(address indexed user, uint256 amount);
    // Event emitted when a user withdraws tokens
    event Withdrawn(address indexed user, uint256 amount);
    // Event emitted when a user borrows tokens
    event Borrowed(address indexed user, uint256 amount, uint256 collateral);
    // Event emitted when a user repays a loan
    event Repaid(address indexed user, uint256 amount);
    // Event emitted when a position is liquidated
    event Liquidated(
        address indexed user,
        uint256 collateralSeized,
        uint256 debtRepaid
    );

    // Constructor initializes the token address
    constructor(address _token) {
        token = IERC20(_token);
    }

    // Allows users to deposit tokens into the lending pool
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        deposits[msg.sender] = deposits[msg.sender].add(amount);
        emit Deposited(msg.sender, amount);
    }

    // Allows users to withdraw their deposited tokens
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(deposits[msg.sender] >= amount, "Insufficient deposit balance");
        deposits[msg.sender] = deposits[msg.sender].sub(amount);
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    // Allows users to borrow tokens against collateral (in ETH)
    function borrow(uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(msg.value > 0, "Collateral required");

        // Update interest before new borrow
        updateInterest(msg.sender);

        // Calculate max borrowable amount based on collateral
        uint256 maxBorrow = msg.value.mul(LTV_RATIO).div(10000);
        require(
            borrows[msg.sender].add(amount) <= maxBorrow,
            "Exceeds LTV ratio"
        );

        // Update state
        borrows[msg.sender] = borrows[msg.sender].add(amount);
        collaterals[msg.sender] = collaterals[msg.sender].add(msg.value);

        // Transfer borrowed tokens
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Borrowed(msg.sender, amount, msg.value);
    }

    // Allows users to repay their loans (principal + interest)
    function repay(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(borrows[msg.sender] > 0, "No active loan");

        // Update interest
        updateInterest(msg.sender);

        // Calculate total debt
        uint256 totalDebt = borrows[msg.sender].add(
            accruedInterest[msg.sender]
        );
        require(amount <= totalDebt, "Amount exceeds debt");

        // Update state
        if (amount >= accruedInterest[msg.sender]) {
            uint256 principalRepaid = amount.sub(accruedInterest[msg.sender]);
            accruedInterest[msg.sender] = 0;
            borrows[msg.sender] = borrows[msg.sender].sub(principalRepaid);
        } else {
            accruedInterest[msg.sender] = accruedInterest[msg.sender].sub(
                amount
            );
        }

        // Transfer repayment tokens
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        emit Repaid(msg.sender, amount);
    }

    // Allows anyone to liquidate undercollateralized positions
    function liquidate(address borrower) external nonReentrant {
        require(borrows[borrower] > 0, "No active loan");

        // Update interest
        updateInterest(borrower);

        // Calculate total debt and collateral value
        uint256 totalDebt = borrows[borrower].add(accruedInterest[borrower]);
        uint256 collateralValue = collaterals[borrower];
        uint256 collateralRatio = totalDebt.mul(10000).div(collateralValue);

        // Check if liquidation threshold is met
        require(
            collateralRatio >= LIQUIDATION_THRESHOLD,
            "Position is healthy"
        );

        // Seize collateral and clear debt
        uint256 collateralSeized = collaterals[borrower];
        collaterals[borrower] = 0;
        borrows[borrower] = 0;
        accruedInterest[borrower] = 0;

        // Transfer collateral to liquidator
        payable(msg.sender).transfer(collateralSeized);
        emit Liquidated(borrower, collateralSeized, totalDebt);
    }

    // Updates accrued interest for a borrower
    function updateInterest(address borrower) internal {
        if (borrows[borrower] == 0) return;

        uint256 timeElapsed = block.timestamp.sub(lastUpdateTime[borrower]);
        if (timeElapsed == 0) return;

        // Calculate interest: Interest = Principal * Rate * Time / Year
        uint256 interest = borrows[borrower]
            .mul(INTEREST_RATE)
            .mul(timeElapsed)
            .div(10000)
            .div(SECONDS_PER_YEAR);

        accruedInterest[borrower] = accruedInterest[borrower].add(interest);
        lastUpdateTime[borrower] = block.timestamp;
    }

    // Returns the total debt (principal + interest) for a borrower
    function getDebt(address borrower) external view returns (uint256) {
        if (borrows[borrower] == 0) return 0;

        uint256 timeElapsed = block.timestamp.sub(lastUpdateTime[borrower]);
        uint256 interest = borrows[borrower]
            .mul(INTEREST_RATE)
            .mul(timeElapsed)
            .div(10000)
            .div(SECONDS_PER_YEAR);

        return borrows[borrower].add(accruedInterest[borrower]).add(interest);
    }
}
