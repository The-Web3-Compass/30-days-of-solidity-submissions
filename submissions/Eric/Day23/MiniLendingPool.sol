//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title MiniLendingPool
 * @author Eric (https://github.com/0xxEric)
 * @notice A platform for Lending
 * @custom:project 30-days-of-solidity-submissions: Day23
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Super-simplified lending pool:
/// - Users deposit "collateralToken" to supply collateral.
/// - Users can borrow "borrowToken" up to LTV * collateralValue.
/// - No interest accrual (to keep it simple).
/// - Liquidator can liquidate undercollateralized positions.
contract MiniLendingPool is Ownable {
    IERC20 public immutable collateralToken;
    IERC20 public immutable borrowToken;
    uint256 public ltvBps = 5000; // 50% LTV by default, expressed in bps (10000 = 100%)

    struct Position {
        uint256 collateral; // collateralToken amount
        uint256 debt;       // borrowToken amount
    }

    mapping(address => Position) public positions;

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Liquidate(address indexed user, address indexed liquidator, uint256 repayAmount);

    constructor(address _collateralToken, address _borrowToken) Ownable(msg.sender) {
        collateralToken = IERC20(_collateralToken);
        borrowToken = IERC20(_borrowToken);
    }

    function setLTV(uint256 bps) external onlyOwner {
        require(bps <= 9000, "ltv too high");
        ltvBps = bps;
    }

    // deposit collateralToken
    function deposit(uint256 amount) external {
        require(amount > 0, "zero");
        collateralToken.transferFrom(msg.sender, address(this), amount);
        positions[msg.sender].collateral += amount;
        emit Deposit(msg.sender, amount);
    }

    // borrow borrowToken; caller must be under LTV after borrowing
    function borrow(uint256 amount) external {
        require(amount > 0, "zero");
        Position storage pos = positions[msg.sender];
        uint256 maxBorrow = (pos.collateral * ltvBps) / 10000;
        require(pos.debt + amount <= maxBorrow, "exceeds ltv");
        pos.debt += amount;
        borrowToken.transfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    // repay debt
    function repay(uint256 amount) external {
        require(amount > 0, "zero");
        Position storage pos = positions[msg.sender];
        uint256 pay = amount > pos.debt ? pos.debt : amount;
        borrowToken.transferFrom(msg.sender, address(this), pay);
        pos.debt -= pay;
        emit Repay(msg.sender, pay);
    }

    // withdraw collateral (must remain collateralized)
    function withdraw(uint256 amount) external {
        Position storage pos = positions[msg.sender];
        require(amount <= pos.collateral, "not enough");
        // ensure after withdrawal, debt <= newCollateral * ltv
        uint256 newCollateral = pos.collateral - amount;
        uint256 maxBorrow = (newCollateral * ltvBps) / 10000;
        require(pos.debt <= maxBorrow, "would breach ltv");
        pos.collateral = newCollateral;
        collateralToken.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    // liquidate undercollateralized position: anyone can repay up to full debt and receive collateral (simple)
    function liquidate(address user) external {
        Position storage pos = positions[user];
        uint256 maxBorrowAllowed = (pos.collateral * ltvBps) / 10000;
        require(pos.debt > maxBorrowAllowed, "not liquidatable");
        // For simplicity: liquidator repays entire debt, receives collateral at 1:1 (no penalty)
        uint256 debt = pos.debt;
        borrowToken.transferFrom(msg.sender, address(this), debt);
        pos.debt = 0;
        uint256 collateral = pos.collateral;
        pos.collateral = 0;
        collateralToken.transfer(msg.sender, collateral);
        emit Liquidate(user, msg.sender, debt);
    }
}
