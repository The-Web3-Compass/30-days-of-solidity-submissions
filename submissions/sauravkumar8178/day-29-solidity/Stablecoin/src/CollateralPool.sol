// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "./StableUSD.sol";
import "./OracleManager.sol";

/// @title Simple over-collateralized stablecoin pool (educational)
/// @notice Simplified demo: single-collateral flow functions included. Use with caution.
contract CollateralPool is ReentrancyGuard, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    StableUSD public immutable stable;
    OracleManager public immutable oracleManager;

    // allowed collateral token => enabled
    mapping(address => bool) public allowedCollateral;

    // per-user per-collateral balances (raw token amounts)
    mapping(address => mapping(address => uint256)) public collateralBalance;

    // collateralization ratio in percent (e.g., 150 => 150%)
    uint256 public collateralizationRatio = 150;
    uint256 public constant PRICE_DECIMALS = 1e8; // chainlink-style 8 decimals

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event Minted(address indexed user, uint256 usdAmount);
    event Redeemed(address indexed user, uint256 usdAmount);

    constructor(address stableAddress, address oracleManagerAddress) {
        stable = StableUSD(stableAddress);
        oracleManager = OracleManager(oracleManagerAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    // manager functions
    function setAllowedCollateral(address token, bool allowed) external onlyRole(MANAGER_ROLE) {
        allowedCollateral[token] = allowed;
    }

    function setCollateralizationRatio(uint256 ratio) external onlyRole(MANAGER_ROLE) {
        require(ratio >= 100, "ratio < 100");
        collateralizationRatio = ratio;
    }

    /// @notice deposit collateral tokens to be used for minting
    function depositCollateral(address token, uint256 amount) external nonReentrant {
        require(allowedCollateral[token], "token not allowed");
        require(amount > 0, "amount 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        collateralBalance[msg.sender][token] += amount;
        emit CollateralDeposited(msg.sender, token, amount);
    }

    /// @notice mint sUSD using a specific collateral token only (simple flow)
    /// @dev collateralAmount: raw token amount (use token decimals)
    /// @param collateralToken token used as collateral
    /// @param collateralAmount amount of collateral token to deposit+lock for minting
    /// @param minUSDOut minimum acceptable sUSD (slippage protection)
    function mintWithCollateral(address collateralToken, uint256 collateralAmount, uint256 minUSDOut) external nonReentrant {
        require(allowedCollateral[collateralToken], "token not allowed");
        require(collateralAmount > 0, "collateral 0");

        (int256 px, uint256 updatedAt) = oracleManager.getPrice(collateralToken);
        require(px > 0, "bad price");
        require(block.timestamp - updatedAt <= 5 minutes, "stale price");

        uint256 price = uint256(px); // price with 8 decimals

        // value of collateral in USD with 18 decimals: collateralAmount * price / 1e8
        // but collateralAmount has token decimals (commonly 18). We'll compute:
        // collateralValueUSD (18 decimals) = collateralAmount * price / PRICE_DECIMALS
        uint256 collateralValueUSD18 = (collateralAmount * price) / PRICE_DECIMALS;

        // max mintable USD (whole units with 18 decimals) = collateralValueUSD18 * 100 / collateralizationRatio
        uint256 maxMintUSD18 = (collateralValueUSD18 * 100) / collateralizationRatio;

        require(maxMintUSD18 >= minUSDOut, "slippage");

        // transfer collateral into the pool
        IERC20(collateralToken).transferFrom(msg.sender, address(this), collateralAmount);
        collateralBalance[msg.sender][collateralToken] += collateralAmount;

        // mint sUSD (sUSD uses 18 decimals)
        stable.mint(msg.sender, maxMintUSD18);

        emit Minted(msg.sender, maxMintUSD18);
    }

    /// @notice redeem sUSD for collateral (single collateral flow)
    /// @param collateralToken token to receive
    /// @param usdAmount amount of sUSD (18 decimals) to burn
    /// @param minCollateralOut minimum collateral token amount (raw token decimals)
    function redeemToCollateral(address collateralToken, uint256 usdAmount, uint256 minCollateralOut) external nonReentrant {
        require(allowedCollateral[collateralToken], "token not allowed");
        require(usdAmount > 0, "usdAmount 0");

        (int256 px, uint256 updatedAt) = oracleManager.getPrice(collateralToken);
        require(px > 0, "bad price");
        require(block.timestamp - updatedAt <= 5 minutes, "stale price");

        uint256 price = uint256(px); // 8 decimals

        // collateral amount (raw token decimals) to return = usdAmount * PRICE_DECIMALS / price
        // Note: usdAmount has 18 decimals; result will be in token raw units (assumes token has 18 decimals)
        uint256 collateralAmount = (usdAmount * PRICE_DECIMALS) / price;

        require(collateralBalance[msg.sender][collateralToken] >= collateralAmount, "insufficient collateral");
        require(collateralAmount >= minCollateralOut, "slippage");

        // burn stable from user
        stable.burn(msg.sender, usdAmount);

        // reduce balance and transfer collateral
        collateralBalance[msg.sender][collateralToken] -= collateralAmount;
        IERC20(collateralToken).transfer(msg.sender, collateralAmount);

        emit Redeemed(msg.sender, usdAmount);
    }
}