// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SimpleStablecoin is ERC20, Ownable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant PRICE_FEED_MANAGER_ROLE = keccak256("PRICE_FEED_MANAGER_ROLE");
    IERC20 public immutable collateralToken;
    uint8 public immutable collateralDecimals;
    AggregatorV3Interface public priceFeed;
    uint256 public collateralizationRatio = 150;
    uint256 public constant MAX_STALENESS_PERIOD = 86400;

    event Minted(address indexed user, uint256 amount, uint256 collateralDeposited);
    event Redeemed(address indexed user, uint256 amount, uint256 collateralReturned);
    event PriceFeedUpdated(address indexed oldPriceFeed, address indexed newPriceFeed);
    event CollateralizationRatioUpdated(uint256 oldRatio, uint256 newRatio);

    error InvalidCollateralTokenAddress();
    error InvalidPriceFeedAddress();
    error MintAmountIsZero();
    error InsufficientStablecoinBalance();
    error CollateralizationRatioTooLow();
    error InvalidPriceFeedResponse();
    error StalePriceFeed();
    error CollateralTransferFailed();

    constructor(
        address _collateralToken,
        address _initialOwner,
        address _priceFeed
    ) ERC20("Simple USD Stablecoin", "sUSD") Ownable(_initialOwner) {
        if (_collateralToken == address(0)) revert InvalidCollateralTokenAddress();
        if (_priceFeed == address(0)) revert InvalidPriceFeedAddress();

        collateralToken = IERC20(_collateralToken);
        collateralDecimals = IERC20Metadata(_collateralToken).decimals();
        priceFeed = AggregatorV3Interface(_priceFeed);

        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        _grantRole(PRICE_FEED_MANAGER_ROLE, _initialOwner);
    }

    function getCurrentPrice() public view returns (uint256) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        if (price <= 0) revert InvalidPriceFeedResponse();
        if (updatedAt == 0) revert InvalidPriceFeedResponse();
        if (answeredInRound < roundId) revert InvalidPriceFeedResponse();
        if (block.timestamp - updatedAt > MAX_STALENESS_PERIOD) revert StalePriceFeed();

        return uint256(price);
    }

    function mint(uint256 amount) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();

        uint256 requiredCollateral = getRequiredCollateralForMint(amount);

        uint256 allowance = collateralToken.allowance(msg.sender, address(this));
        if (allowance < requiredCollateral) revert CollateralTransferFailed();

        collateralToken.safeTransferFrom(msg.sender, address(this), requiredCollateral);
        _mint(msg.sender, amount);

        emit Minted(msg.sender, amount, requiredCollateral);
    }

    function redeem(uint256 amount) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();
        if (balanceOf(msg.sender) < amount) revert InsufficientStablecoinBalance();

        uint256 collateralToReturn = getCollateralForRedeem(amount);

        _burn(msg.sender, amount);
        collateralToken.safeTransfer(msg.sender, collateralToReturn);

        emit Redeemed(msg.sender, amount, collateralToReturn);
    }

    function setCollateralizationRatio(uint256 newRatio) external onlyOwner {
        if (newRatio < 100) revert CollateralizationRatioTooLow();
        uint256 oldRatio = collateralizationRatio;
        collateralizationRatio = newRatio;
        emit CollateralizationRatioUpdated(oldRatio, newRatio);
    }

    function setPriceFeedContract(address _newPriceFeed) external onlyRole(PRICE_FEED_MANAGER_ROLE) {
        if (_newPriceFeed == address(0)) revert InvalidPriceFeedAddress();
        address oldPriceFeed = address(priceFeed);
        priceFeed = AggregatorV3Interface(_newPriceFeed);
        emit PriceFeedUpdated(oldPriceFeed, _newPriceFeed);
    }

    function getRequiredCollateralForMint(uint256 amount) public view returns (uint256) {
        if (amount == 0) return 0;

        uint256 collateralPrice = getCurrentPrice();
        uint256 requiredCollateralValueUSD = amount * collateralizationRatio;
        return (requiredCollateralValueUSD * (10 ** (collateralDecimals + priceFeed.decimals()))) /
               (100 * collateralPrice * (10 ** decimals()));
    }

    function getCollateralForRedeem(uint256 amount) public view returns (uint256) {
        if (amount == 0) return 0;

        uint256 collateralPrice = getCurrentPrice();
        uint256 stablecoinValueUSD = amount * 100;
        return (stablecoinValueUSD * (10 ** (collateralDecimals + priceFeed.decimals()))) /
               (collateralizationRatio * collateralPrice * (10 ** decimals()));
    }

    function getSystemCollateralization() external view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) return type(uint256).max; 

        uint256 collateralBalance = collateralToken.balanceOf(address(this));
        uint256 collateralPrice = getCurrentPrice();
        uint256 collateralValueUSD = (collateralBalance * collateralPrice * (10 ** decimals())) /
                                    (10 ** (collateralDecimals + priceFeed.decimals()));

        return (collateralValueUSD * 100) / totalSupply;
    }
}