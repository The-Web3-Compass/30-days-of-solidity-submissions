// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EnhancedStablecoin is ERC20, Ownable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant PRICE_FEED_MANAGER_ROLE = keccak256("PRICE_FEED_MANAGER_ROLE");
    IERC20 public immutable collateralToken;
    uint8 public immutable collateralDecimals;
    AggregatorV3Interface public priceFeed;

    uint256 public collateralizationRatio = 150; // Expressed as a percentage (150 = 150%)
    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120%

    mapping(address => uint256) public collateralDeposited;
    mapping(address => uint256) public userDebt;

    event Minted(address indexed user, uint256 amount, uint256 collateralDeposited);
    event Redeemed(address indexed user, uint256 amount, uint256 collateralReturned);
    event PriceFeedUpdated(address newPriceFeed);
    event CollateralizationRatioUpdated(uint256 newRatio);
    event Liquidated(address indexed user, address indexed liquidator, uint256 debtRepaid, uint256 collateralSeized);

    error InvalidCollateralTokenAddress();
    error InvalidPriceFeedAddress();
    error MintAmountIsZero();
    error InsufficientStablecoinBalance();
    error CollateralizationRatioTooLow();
    error PositionNotLiquidatable();
    error InsufficientCollateral();

    constructor(
        address _collateralToken,
        address _initialOwner,
        address _priceFeed
    ) ERC20("Enhanced USD Stablecoin", "eUSD") Ownable(_initialOwner) {
        if (_collateralToken == address(0)) revert InvalidCollateralTokenAddress();
        if (_priceFeed == address(0)) revert InvalidPriceFeedAddress();

        collateralToken = IERC20(_collateralToken);
        collateralDecimals = IERC20Metadata(_collateralToken).decimals();
        priceFeed = AggregatorV3Interface(_priceFeed);

        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        _grantRole(PRICE_FEED_MANAGER_ROLE, _initialOwner);
    }

    function getCurrentPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed response");
        return uint256(price);
    }

    function getHealthFactor(address user) public view returns (uint256) {
        uint256 collateralValue = (collateralDeposited[user] * getCurrentPrice()) / (10 ** priceFeed.decimals());
        if (userDebt[user] == 0) return type(uint256).max;
        return (collateralValue * 100) / userDebt[user];
    }

    function mint(uint256 amount, uint256 collateralAmount) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();

        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        collateralDeposited[msg.sender] += collateralAmount;

        uint256 collateralValue = (collateralDeposited[msg.sender] * getCurrentPrice()) / (10 ** priceFeed.decimals());
        uint256 maxMintable = (collateralValue * 100) / collateralizationRatio;

        require(userDebt[msg.sender] + amount <= maxMintable, "Exceeds max mintable amount");

        userDebt[msg.sender] += amount;
        _mint(msg.sender, amount);

        emit Minted(msg.sender, amount, collateralAmount);
    }

    function redeem(uint256 amount, uint256 collateralToWithdraw) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();
        if (balanceOf(msg.sender) < amount) revert InsufficientStablecoinBalance();
        if (collateralDeposited[msg.sender] < collateralToWithdraw) revert InsufficientCollateral();

        _burn(msg.sender, amount);
        userDebt[msg.sender] -= amount;

        uint256 collateralValue = (collateralDeposited[msg.sender] * getCurrentPrice()) / (10 ** priceFeed.decimals());
        uint256 maxMintable = (collateralValue * 100) / collateralizationRatio;
        require(userDebt[msg.sender] <= maxMintable, "Position would be undercollateralized");

        collateralDeposited[msg.sender] -= collateralToWithdraw;
        collateralToken.safeTransfer(msg.sender, collateralToWithdraw);

        emit Redeemed(msg.sender, amount, collateralToWithdraw);
    }

    function liquidate(address user) external nonReentrant {
        uint256 healthFactor = getHealthFactor(user);
        if (healthFactor >= LIQUIDATION_THRESHOLD) revert PositionNotLiquidatable();

        uint256 debtToRepay = userDebt[user];
        require(balanceOf(msg.sender) >= debtToRepay, "Insufficient balance to liquidate");

        uint256 collateralToSeize = (debtToRepay * (10 ** priceFeed.decimals())) / getCurrentPrice();
        require(collateralToSeize <= collateralDeposited[user], "Not enough collateral to seize");

        _burn(msg.sender, debtToRepay);
        userDebt[user] = 0;
        collateralDeposited[user] -= collateralToSeize;

        collateralToken.safeTransfer(msg.sender, collateralToSeize);

        emit Liquidated(user, msg.sender, debtToRepay, collateralToSeize);
    }

    function setCollateralizationRatio(uint256 newRatio) external onlyOwner {
        if (newRatio < 100) revert CollateralizationRatioTooLow();
        collateralizationRatio = newRatio;
        emit CollateralizationRatioUpdated(newRatio);
    }

    function setPriceFeedContract(address _newPriceFeed) external onlyRole(PRICE_FEED_MANAGER_ROLE) {
        if (_newPriceFeed == address(0)) revert InvalidPriceFeedAddress();
        priceFeed = AggregatorV3Interface(_newPriceFeed);
        emit PriceFeedUpdated(_newPriceFeed);
    }
}