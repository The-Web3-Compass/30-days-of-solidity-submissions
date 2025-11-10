// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Chainlink price feed interface (minimal)
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (uint80, int256 answer, uint256, uint256, uint80);
}

/**
 * @title SimpleStablecoin
 * @notice Educational over-collateralized stablecoin with a live price feed.
 * - Collateral token is immutable
 * - 150% collateralization by default (owner adjustable >= 100)
 */
contract SimpleStablecoin is ERC20, Ownable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant PRICE_FEED_MANAGER_ROLE = keccak256("PRICE_FEED_MANAGER_ROLE");

    IERC20 public immutable collateralToken;
    uint8 public immutable collateralDecimals;
    AggregatorV3Interface public priceFeed;
    uint256 public collateralizationRatio = 150; // percent (e.g., 150 = 150%)

    event Minted(address indexed user, uint256 amount, uint256 collateralDeposited);
    event Redeemed(address indexed user, uint256 amount, uint256 collateralReturned);
    event PriceFeedUpdated(address newPriceFeed);
    event CollateralizationRatioUpdated(uint256 newRatio);

    error InvalidCollateralTokenAddress();
    error InvalidPriceFeedAddress();
    error MintAmountIsZero();
    error InsufficientStablecoinBalance();
    error CollateralizationRatioTooLow();

    constructor(address _collateralToken, address _initialOwner, address _priceFeed)
        ERC20("Simple USD Stablecoin", "sUSD")
        Ownable(_initialOwner)
    {
        if (_collateralToken == address(0)) revert InvalidCollateralTokenAddress();
        if (_priceFeed == address(0)) revert InvalidPriceFeedAddress();

        collateralToken = IERC20(_collateralToken);
        collateralDecimals = IERC20Metadata(_collateralToken).decimals();
        priceFeed = AggregatorV3Interface(_priceFeed);

        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        _grantRole(PRICE_FEED_MANAGER_ROLE, _initialOwner);
    }

    function getCurrentPrice() public view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price); // scaled by priceFeed.decimals()
    }

    /// @notice Mint `amount` sUSD to caller, depositing required collateral
    function mint(uint256 amount) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();

        uint256 price = getCurrentPrice();
        uint8 pfDec = priceFeed.decimals();

        // USD value uses 18 decimals (sUSD decimals)
        uint256 usdValue = amount * (10 ** decimals());

        // required collateral (in USD) * ratio / (100 * price)
        uint256 requiredCollateral = (usdValue * collateralizationRatio) / (100 * price);

        // scale to collateral token decimals from price feed decimals
        uint256 adjustedRequired = (requiredCollateral * (10 ** collateralDecimals)) / (10 ** pfDec);

        collateralToken.safeTransferFrom(msg.sender, address(this), adjustedRequired);
        _mint(msg.sender, amount);

        emit Minted(msg.sender, amount, adjustedRequired);
    }

    /// @notice Burn `amount` sUSD to redeem collateral
    function redeem(uint256 amount) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();
        if (balanceOf(msg.sender) < amount) revert InsufficientStablecoinBalance();

        uint256 price = getCurrentPrice();
        uint8 pfDec = priceFeed.decimals();

        uint256 usdValue = amount * (10 ** decimals());

        // how much collateral to return (inverse of mint math)
        uint256 collateralToReturn = (usdValue * 100) / (collateralizationRatio * price);
        uint256 adjustedReturn = (collateralToReturn * (10 ** collateralDecimals)) / (10 ** pfDec);

        _burn(msg.sender, amount);
        collateralToken.safeTransfer(msg.sender, adjustedReturn);

        emit Redeemed(msg.sender, amount, adjustedReturn);
    }

    function setCollateralizationRatio(uint256 newRatio) external onlyOwner {
        if (newRatio < 100) revert CollateralizationRatioTooLow();
        collateralizationRatio = newRatio;
        emit CollateralizationRatioUpdated(newRatio);
    }

    function setPriceFeedContract(address _new) external onlyRole(PRICE_FEED_MANAGER_ROLE) {
        if (_new == address(0)) revert InvalidPriceFeedAddress();
        priceFeed = AggregatorV3Interface(_new);
        emit PriceFeedUpdated(_new);
    }

    // helper views for UI/frontends
    function getRequiredCollateralForMint(uint256 amount) external view returns (uint256) {
        if (amount == 0) return 0;
        uint256 price = getCurrentPrice();
        uint8 pfDec = priceFeed.decimals();
        uint256 usdValue = amount * (10 ** decimals());
        uint256 req = (usdValue * collateralizationRatio) / (100 * price);
        return (req * (10 ** collateralDecimals)) / (10 ** pfDec);
    }

    function getCollateralForRedeem(uint256 amount) external view returns (uint256) {
        if (amount == 0) return 0;
        uint256 price = getCurrentPrice();
        uint8 pfDec = priceFeed.decimals();
        uint256 usdValue = amount * (10 ** decimals());
        uint256 back = (usdValue * 100) / (collateralizationRatio * price);
        return (back * (10 ** collateralDecimals)) / (10 ** pfDec);
    }
}
