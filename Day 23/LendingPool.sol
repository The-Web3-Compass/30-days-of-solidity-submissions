// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Simple Lending Pool
/// @notice Demonstrates basic DeFi lending, borrowing, and collateral logic
contract LendingPool is Ownable {
    IERC20 public depositToken;     // e.g., DAI
    IERC20 public collateralToken;  // e.g., ETH (wrapped)
    
    uint256 public interestRate = 5; // 5% simple interest per borrow
    uint256 public collateralRatio = 150; // 150% collateral required

    struct Position {
        uint256 depositBalance;
        uint256 borrowBalance;
        uint256 collateralAmount;
    }

    mapping(address => Position) public userPositions;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    constructor(address _depositToken, address _collateralToken, address _owner)
        Ownable(_owner)
    {
        depositToken = IERC20(_depositToken);
        collateralToken = IERC20(_collateralToken);
    }

    // Users deposit tokens to provide liquidity
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        depositToken.transferFrom(msg.sender, address(this), amount);
        userPositions[msg.sender].depositBalance += amount;
        emit Deposited(msg.sender, amount);
    }

    // Borrow tokens against collateral
    function borrow(uint256 amount) external {
        Position storage pos = userPositions[msg.sender];
        require(pos.collateralAmount > 0, "No collateral");
        
        uint256 maxBorrow = (pos.collateralAmount * 100) / collateralRatio;
        require(amount <= maxBorrow, "Exceeds borrow limit");

        pos.borrowBalance += amount + calculateInterest(amount);
        depositToken.transfer(msg.sender, amount);

        emit Borrowed(msg.sender, amount);
    }

    // Provide collateral (e.g., wrapped ETH)
    function depositCollateral(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        collateralToken.transferFrom(msg.sender, address(this), amount);
        userPositions[msg.sender].collateralAmount += amount;
    }

    // Repay borrowed funds
    function repay(uint256 amount) external {
        Position storage pos = userPositions[msg.sender];
        require(pos.borrowBalance > 0, "No active loan");
        require(amount <= pos.borrowBalance, "Too much repayment");

        depositToken.transferFrom(msg.sender, address(this), amount);
        pos.borrowBalance -= amount;

        emit Repaid(msg.sender, amount);
    }

    // Withdraw collateral after full repayment
    function withdrawCollateral(uint256 amount) external {
        Position storage pos = userPositions[msg.sender];
        require(pos.borrowBalance == 0, "Outstanding loan");
        require(amount <= pos.collateralAmount, "Exceeds collateral");

        pos.collateralAmount -= amount;
        collateralToken.transfer(msg.sender, amount);

        emit CollateralWithdrawn(msg.sender, amount);
    }

    // --- INTERNAL ---
    function calculateInterest(uint256 amount) internal view returns (uint256) {
        return (amount * interestRate) / 100;
    }
}
