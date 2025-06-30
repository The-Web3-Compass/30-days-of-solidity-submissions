/**
 * @title Stablecoin
 * @dev 稳定币
 * 功能点：重点是通过稳定币机制扩展 DeFi
 * 
 * 【设计思路与核心概念解释】
 * 
 * 1. 保持稳定价值的数字货币：
 *    - 与传统加密货币不同，稳定币旨在减少价格波动
 *    - 为用户提供一种可靠的价值存储和交易媒介
 * 
 * 2. 使用挂钩机制保持价格稳定：
 *    - 本合约使用超额抵押机制，要求用户提供价值更高的抵押品
 *    - 通过150%的抵押率确保稳定币有足够的价值支持
 *    - 例如 存入150美元的ETH，可以借出100美元的稳定币
 * 
 * 3. 演示稳定币机制：
 *    - 完整实现了抵押、铸造、偿还和清算流程
 *    - 类似于有抵押的贷款系统
 * 
 * 4. 锚定机制（Peg Mechanisms）：
 *    - 价格锚定到1美元（通过targetPrice变量）
 *    - 使用抵押品价格预言机和清算机制维持锚定
 * 
 * 【流程】
 * 
 * 用户操作:
 * 1. 创建借贷仓位 (createPosition)
 *    - 用户授权合约使用其抵押品代币
 *    - 用户调用createPosition，指定抵押量和铸造量
 *    - 系统检查抵押率是否满足≥150%要求
 *    - 系统铸造稳定币并转给用户
 * 
 * 2. 管理仓位
 *    - 增加抵押 (addCollateral): 用户可随时增加抵押品
 *    - 减少抵押 (removeCollateral): 用户可在保持抵押率的情况下取回部分抵押品
 *    - 偿还债务 (repayDebt): 用户可偿还部分或全部债务，全部还清时返还抵押品
 * 
 * 3. 仓位清算 (liquidate)
 *    - 当抵押品价值下跌，使仓位健康度低于125%时
 *    - 任何人可以成为清算人，偿还部分债务
 *    - 清算人获得相应抵押品加上5%奖励
 * 
 * 4. 查询功能
 *    - 查看仓位健康度 (getPositionHealth)
 *    - 获取仓位详细信息 (getPosition)：抵押量、债务量、抵押率、清算价格
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Stablecoin is ERC20, ReentrancyGuard, Ownable {
    using Math for uint256;

    // 状态变量
    IERC20 public collateralToken;  // 抵押品代币
    uint256 public constant PRICE_PRECISION = 1e18;  // 价格精度
    uint256 public constant COLLATERAL_RATIO = 150;  // 抵押率 150%
    uint256 public constant LIQUIDATION_THRESHOLD = 125;  // 清算阈值 125%
    uint256 public constant LIQUIDATION_BONUS = 5;  // 清算奖励 5%
    uint256 public constant MIN_COLLATERAL = 100e18;  // 最小抵押量

    // 价格相关
    uint256 public targetPrice = PRICE_PRECISION;  // 目标价格 1美元
    uint256 public collateralPrice;  // 抵押品价格

    // 铸造位置结构体
    struct Position {
        uint256 collateralAmount;  // 抵押品数量
        uint256 debtAmount;       // 债务数量
        uint256 lastInterestTime;  // 上次计息时间
    }

    // 用户位置映射
    mapping(address => Position) public positions;

    // 系统参数
    uint256 public constant INTEREST_RATE = 5e16;  // 年化利率 5%
    uint256 public constant SECONDS_PER_YEAR = 31536000;  // 每年秒数

    // 事件
    event PositionCreated(address indexed user, uint256 collateralAmount, uint256 mintedAmount);
    event PositionClosed(address indexed user, uint256 collateralAmount, uint256 debtAmount);
    event CollateralAdded(address indexed user, uint256 amount);
    event CollateralRemoved(address indexed user, uint256 amount);
    event Liquidated(
        address indexed user,
        address indexed liquidator,
        uint256 collateralLiquidated,
        uint256 debtRepaid
    );
    event PriceUpdated(uint256 newPrice);

    constructor(
        address _collateralToken,
        uint256 _initialCollateralPrice
    ) ERC20("USD Stablecoin", "USDS") Ownable(msg.sender) {
        collateralToken = IERC20(_collateralToken);
        collateralPrice = _initialCollateralPrice;
    }

    /**
     * @dev 创建借贷仓位
     */
    function createPosition(
        uint256 collateralAmount,
        uint256 mintAmount
    ) external nonReentrant {
        require(collateralAmount >= MIN_COLLATERAL, "Insufficient collateral");
        require(mintAmount > 0, "Invalid mint amount");

        // 检查抵押率
        uint256 collateralValue = (collateralAmount * collateralPrice) / PRICE_PRECISION;
        uint256 mintValue = (mintAmount * targetPrice) / PRICE_PRECISION;
        require(
            collateralValue * 100 >= mintValue * COLLATERAL_RATIO,
            "Insufficient collateral ratio"
        );

        // 转入抵押品
        collateralToken.transferFrom(msg.sender, address(this), collateralAmount);

        // 创建仓位
        positions[msg.sender] = Position({
            collateralAmount: collateralAmount,
            debtAmount: mintAmount,
            lastInterestTime: block.timestamp
        });

        // 铸造稳定币
        _mint(msg.sender, mintAmount);

        emit PositionCreated(msg.sender, collateralAmount, mintAmount);
    }

    /**
     * @dev 添加抵押品
     */
    function addCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        Position storage position = positions[msg.sender];
        require(position.collateralAmount > 0, "No existing position");

        // 更新利息
        _updateInterest(msg.sender);

        // 转入抵押品
        collateralToken.transferFrom(msg.sender, address(this), amount);
        position.collateralAmount += amount;

        emit CollateralAdded(msg.sender, amount);
    }

    /**
     * @dev 移除抵押品
     */
    function removeCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        Position storage position = positions[msg.sender];
        require(position.collateralAmount >= amount, "Insufficient collateral");

        // 更新利息
        _updateInterest(msg.sender);

        // 检查移除后的抵押率
        uint256 newCollateralValue = ((position.collateralAmount - amount) * collateralPrice) / PRICE_PRECISION;
        uint256 debtValue = (position.debtAmount * targetPrice) / PRICE_PRECISION;
        require(
            newCollateralValue * 100 >= debtValue * COLLATERAL_RATIO,
            "Would break collateral ratio"
        );

        // 转出抵押品
        position.collateralAmount -= amount;
        collateralToken.transfer(msg.sender, amount);

        emit CollateralRemoved(msg.sender, amount);
    }

    /**
     * @dev 偿还债务
     */
    function repayDebt(uint256 amount) external nonReentrant {
        Position storage position = positions[msg.sender];
        require(position.debtAmount > 0, "No debt to repay");
        require(amount <= position.debtAmount, "Amount exceeds debt");

        // 更新利息
        _updateInterest(msg.sender);

        // 销毁稳定币
        _burn(msg.sender, amount);
        position.debtAmount -= amount;

        // 如果完全还清，返还抵押品
        if (position.debtAmount == 0) {
            uint256 collateralToReturn = position.collateralAmount;
            position.collateralAmount = 0;
            collateralToken.transfer(msg.sender, collateralToReturn);
            emit PositionClosed(msg.sender, collateralToReturn, amount);
        }
    }

    /**
     * @dev 清算不健康的仓位
     */
    function liquidate(address user, uint256 debtAmount) external nonReentrant {
        Position storage position = positions[user];
        require(position.debtAmount > 0, "No debt to liquidate");
        require(debtAmount <= position.debtAmount, "Amount exceeds debt");

        // 更新利息
        _updateInterest(user);

        // 检查是否可以清算
        uint256 collateralValue = (position.collateralAmount * collateralPrice) / PRICE_PRECISION;
        uint256 debtValue = (position.debtAmount * targetPrice) / PRICE_PRECISION;
        require(
            collateralValue * 100 < debtValue * LIQUIDATION_THRESHOLD,
            "Position not liquidatable"
        );

        // 计算清算数量
        uint256 collateralToLiquidate = (debtAmount * targetPrice * (100 + LIQUIDATION_BONUS)) / 
            (collateralPrice * 100);
        require(collateralToLiquidate <= position.collateralAmount, "Too much collateral requested");

        // 执行清算
        position.collateralAmount -= collateralToLiquidate;
        position.debtAmount -= debtAmount;
        _burn(msg.sender, debtAmount);
        collateralToken.transfer(msg.sender, collateralToLiquidate);

        emit Liquidated(user, msg.sender, collateralToLiquidate, debtAmount);
    }

    /**
     * @dev 更新抵押品价格（仅管理员）
     */
    function updateCollateralPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Invalid price");
        collateralPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    /**
     * @dev 内部函数：更新利息
     */
    function _updateInterest(address user) internal {
        Position storage position = positions[user];
        if (position.debtAmount == 0) return;

        uint256 timePassed = block.timestamp - position.lastInterestTime;
        if (timePassed == 0) return;

        uint256 interest = (position.debtAmount * INTEREST_RATE * timePassed) / 
            (SECONDS_PER_YEAR * 100);
        position.debtAmount += interest;
        position.lastInterestTime = block.timestamp;
    }

    /**
     * @dev 获取仓位健康度
     */
    function getPositionHealth(address user) external view returns (uint256) {
        Position storage position = positions[user];
        if (position.debtAmount == 0) return type(uint256).max;

        uint256 collateralValue = (position.collateralAmount * collateralPrice) / PRICE_PRECISION;
        uint256 debtValue = (position.debtAmount * targetPrice) / PRICE_PRECISION;
        return (collateralValue * 100) / debtValue;
    }

    /**
     * @dev 获取仓位信息
     */
    function getPosition(address user) external view returns (
        uint256 collateralAmount,
        uint256 debtAmount,
        uint256 collateralRatio,
        uint256 liquidationPrice
    ) {
        Position storage position = positions[user];
        collateralAmount = position.collateralAmount;
        debtAmount = position.debtAmount;

        if (debtAmount > 0) {
            uint256 collateralValue = (collateralAmount * collateralPrice) / PRICE_PRECISION;
            uint256 debtValue = (debtAmount * targetPrice) / PRICE_PRECISION;
            collateralRatio = (collateralValue * 100) / debtValue;
            liquidationPrice = (debtValue * LIQUIDATION_THRESHOLD * PRICE_PRECISION) / 
                (collateralAmount * 100);
        }
    }
}