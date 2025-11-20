// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract AdvancedLendingPool is ReentrancyGuard {

    // --------------------------------------------------
    //                STATE VARIABLES
    // --------------------------------------------------

    IERC20 public immutable stableToken;  // e.g., DAI/USDC borrowed by users

    mapping(address => uint256) public depositBalances;       // ETH deposits
    mapping(address => uint256) public collateralBalances;    // ETH collateral
    mapping(address => uint256) public borrowBalances;        // ERC20 debt

    mapping(address => uint256) public lastInterestAccrual;   // timestamp

    uint256 public interestRateBP = 500;          // 5% APR
    uint256 public collateralFactorBP = 7500;     // 75% LTV
    uint256 public liquidationThresholdBP = 8500; // 85% → liquidatable
    uint256 public liquidationBonusBP = 11000;    // liquidator gets 10% bonus


    // --------------------------------------------------
    //                    EVENTS
    // --------------------------------------------------

    event DepositETH(address indexed user, uint256 amount);
    event WithdrawETH(address indexed user, uint256 amount);

    event CollateralAdded(address indexed user, uint256 amount);
    event CollateralRemoved(address indexed user, uint256 amount);

    event Borrow(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    
    event Liquidated(address indexed liquidator, address indexed user,
                     uint256 debtRepaid, uint256 collateralTaken);


    // --------------------------------------------------
    //                CONSTRUCTOR
    // --------------------------------------------------

    constructor(IERC20 _stable) {
        stableToken = _stable;
    }


    // --------------------------------------------------
    //              INTERNAL INTEREST LOGIC
    // --------------------------------------------------

    function _calculateDebt(address user) internal view returns (uint256) {
        uint256 principal = borrowBalances[user];
        if (principal == 0) return 0;

        uint256 timeElapsed = block.timestamp - lastInterestAccrual[user];

        uint256 interest = (principal * interestRateBP * timeElapsed)
                            / (10000 * 365 days);

        return principal + interest;
    }

    function _updateInterest(address user) internal {
        uint256 newDebt = _calculateDebt(user);
        borrowBalances[user] = newDebt;
        lastInterestAccrual[user] = block.timestamp;
    }


    // --------------------------------------------------
    //                DEPOSIT & WITHDRAW
    // --------------------------------------------------

    function depositETH() external payable nonReentrant {
        require(msg.value > 0, "Deposit > 0");

        depositBalances[msg.sender] += msg.value;

        emit DepositETH(msg.sender, msg.value);
    }

    function withdrawETH(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdraw > 0");
        require(depositBalances[msg.sender] >= amount, "Not enough");

        depositBalances[msg.sender] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit WithdrawETH(msg.sender, amount);
    }


    // --------------------------------------------------
    //                COLLATERAL MANAGEMENT
    // --------------------------------------------------

    function depositCollateral() external payable nonReentrant {
        require(msg.value > 0, "Must deposit > 0");

        collateralBalances[msg.sender] += msg.value;

        emit CollateralAdded(msg.sender, msg.value);
    }

    function withdrawCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdraw > 0");
        require(collateralBalances[msg.sender] >= amount, "Not enough collateral");

        _updateInterest(msg.sender);  // bring debt current

        uint256 debt = borrowBalances[msg.sender];
        uint256 maxAllowed = (collateralBalances[msg.sender] * collateralFactorBP) / 10000;

        require(debt <= maxAllowed - amount, "Unsafe withdraw");

        collateralBalances[msg.sender] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit CollateralRemoved(msg.sender, amount);
    }


    // --------------------------------------------------
    //                      BORROW
    // --------------------------------------------------

    function borrow(uint256 amount) external nonReentrant {
        require(amount > 0, "Borrow > 0");

        _updateInterest(msg.sender);

        uint256 maxBorrow = (collateralBalances[msg.sender] * collateralFactorBP) / 10000;

        require(borrowBalances[msg.sender] + amount <= maxBorrow,
                "Exceeds LTV");

        borrowBalances[msg.sender] += amount;
        lastInterestAccrual[msg.sender] = block.timestamp;

        require(stableToken.transfer(msg.sender, amount), "ERC20 transfer fail");

        emit Borrow(msg.sender, amount);
    }


    // --------------------------------------------------
    //                     REPAY
    // --------------------------------------------------

    function repay(uint256 amount) external nonReentrant {
        require(amount > 0, "Repay > 0");

        _updateInterest(msg.sender);

        uint256 debt = borrowBalances[msg.sender];
        uint256 pay = amount > debt ? debt : amount;

        require(stableToken.transferFrom(msg.sender, address(this), pay),
                "ERC20 transfer fail");

        borrowBalances[msg.sender] -= pay;

        emit Repaid(msg.sender, pay);
    }


    // --------------------------------------------------
    //                 LIQUIDATION LOGIC
    // --------------------------------------------------

    function liquidate(address user, uint256 repayAmount) external nonReentrant {
        _updateInterest(user);

        uint256 debt = borrowBalances[user];
        require(debt > 0, "User not in debt");

        uint256 threshold = (collateralBalances[user] * liquidationThresholdBP) / 10000;
        require(debt >= threshold, "Position not liquidatable");

        uint256 pay = repayAmount > debt ? debt : repayAmount;

        require(stableToken.transferFrom(msg.sender, address(this), pay),
                "Liquidator transfer fail");

        uint256 collateralReward =
            (pay * liquidationBonusBP) / 10000;

        require(collateralBalances[user] >= collateralReward, "Not enough collateral");

        collateralBalances[user] -= collateralReward;

        (bool success,) = payable(msg.sender).call{value: collateralReward}("");
        require(success, "Transfer fail");

        borrowBalances[user] -= pay;

        emit Liquidated(msg.sender, user, pay, collateralReward);
    }
}
