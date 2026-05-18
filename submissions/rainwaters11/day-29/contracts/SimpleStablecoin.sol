// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title  SimpleStablecoin (SUSD)
/// @author rainwaters11 — Day 29: The Digital Pawn Shop
/// @notice A minimal ETH-collateralized stablecoin that pegs 1 SUSD ≈ $1 USD.
///
/// @dev    PAWN SHOP ANALOGY
///         ┌───────────────────────────────────────────────────────────┐
///         │  Deposit  → You bring Gold (ETH) to the shop.             │
///         │  Loan     → Shop gives Store Credit (SUSD). Only $100 of  │
///         │             credit per $150 of gold (150% ratio).          │
///         │  Retrieve → Burn the SUSD to get your ETH back.           │
///         └───────────────────────────────────────────────────────────┘
///
///         ORACLE NORMALIZATION (the "1e10 professional touch")
///         Chainlink's ETH/USD feed returns prices with 8 decimal places,
///         e.g. $2,000.00000000 is returned as 200_000_000_000.
///         Solidity represents ETH amounts in 18-decimal wei.
///         If we used the raw 8-decimal price in our math, we'd be off by
///         10^10 — turning a $1 mint into a $10,000,000,000 mint silently.
///
///         Fix: multiply by PRICE_FEED_SCALE (= 10 ** (18 - 8) = 1e10)
///         to normalize every Chainlink price to 18 decimals before any
///         arithmetic.  All internal math then operates in a consistent
///         18-decimal universe.
///
///         HEALTH FACTOR
///         healthFactor = (collateralValueUSD * 100) / (mintedSUSD * COLLATERAL_RATIO)
///         A position is safe when healthFactor ≥ 1 (i.e. collateral covers
///         the required over-collateralization).  withdrawCollateral blocks any
///         withdrawal that would push the caller's health factor below 1.
///
///         USE CASES IN MISTYCOIN-CORE
///         • Day 18 Farmers  — receive crop payouts in SUSD, immune to ETH volatility.
///         • Day 17 Subscribers — pay predictable monthly fees denominated in SUSD.
contract SimpleStablecoin is ERC20, Ownable, ReentrancyGuard {

    // ─── Constants ────────────────────────────────────────────────────────────

    /// @notice Minimum collateralization ratio (150 %).
    ///         For every $1 of SUSD minted, $1.50 of ETH must be locked.
    uint256 public constant COLLATERAL_RATIO = 150;

    /// @notice Precision divisor for COLLATERAL_RATIO (basis is 100 %).
    uint256 public constant RATIO_PRECISION = 100;

    /// @notice Chainlink ETH/USD returns 8 decimal places.
    ///         We normalize to 18 decimals so every price lives in the same
    ///         unit system as wei.  1e10 = 10 ** (18 - 8).
    uint256 public constant PRICE_FEED_SCALE = 1e10;

    /// @notice 18-decimal precision used throughout the contract.
    uint256 public constant PRECISION = 1e18;

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice Chainlink ETH/USD price feed (8 decimals on mainnet/testnets).
    AggregatorV3Interface public priceFeed;

    /// @dev Maps each user to their locked ETH collateral (in wei).
    mapping(address => uint256) public collateralDeposited;

    /// @dev Maps each user to the amount of SUSD they have minted.
    mapping(address => uint256) public susdMinted;

    // ─── Events ───────────────────────────────────────────────────────────────

    event CollateralDeposited(address indexed user, uint256 ethAmount);
    event StablecoinMinted(address indexed user, uint256 susdAmount);
    event StablecoinBurned(address indexed user, uint256 susdAmount);
    event CollateralWithdrawn(address indexed user, uint256 ethAmount);
    event PriceFeedUpdated(address indexed newFeed);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error ZeroAmount();
    error InvalidPriceFeed();
    error ExceedsMaxMintable();         // would breach 150% ratio
    error HealthFactorTooLow();         // withdrawal puts position at risk
    error InsufficientCollateral();     // not enough ETH locked
    error InsufficientSUSDBalance();    // not enough SUSD to burn
    error ETHTransferFailed();
    error StalePrice();

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @param _priceFeed   Chainlink AggregatorV3Interface (ETH/USD, 8 dec).
    /// @param _owner       Initial owner (can update the price feed address).
    constructor(address _priceFeed, address _owner)
        ERC20("Simple USD Stablecoin", "SUSD")
        Ownable(_owner)
    {
        if (_priceFeed == address(0)) revert InvalidPriceFeed();
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // ─── Oracle ───────────────────────────────────────────────────────────────

    /// @notice Fetches the current ETH price from Chainlink and normalizes it
    ///         to 18 decimal places.
    ///
    /// @dev    NORMALIZATION DETAIL
    ///         Chainlink's ETH/USD feed returns 8 decimal places.
    ///         Example: $2,000.00 → raw value 200_000_000_000 (11 digits).
    ///
    ///         Without scaling:  200_000_000_000  (8 dec)
    ///         With × 1e10:  2_000_000_000_000_000_000_000  (18 dec)
    ///
    ///         All subsequent math (mintable amounts, health factor) uses this
    ///         18-decimal price so there is never an off-by-1e10 silent error.
    ///
    /// @return ethPriceUSD  Current ETH price in USD, scaled to 18 decimals.
    function getEthPrice() public view returns (uint256 ethPriceUSD) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // Sanity checks — never trust a stale or negative price.
        if (price <= 0)                    revert StalePrice();
        if (answeredInRound < roundId)     revert StalePrice();
        if (updatedAt == 0)                revert StalePrice();

        // ✨ THE PROFESSIONAL TOUCH: scale 8-decimal Chainlink price → 18 dec.
        //    Prevents "silent math failures" where $1 mint becomes $10B.
        ethPriceUSD = uint256(price) * PRICE_FEED_SCALE;
    }

    // ─── Core: Deposit collateral ──────────────────────────────────────────────

    /// @notice Lock ETH as collateral.  ETH is the "Gold" in the pawn shop.
    ///         Call this before (or alongside) mintStablecoin.
    function depositCollateral() external payable nonReentrant {
        if (msg.value == 0) revert ZeroAmount();

        collateralDeposited[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    // ─── Core: Mint stablecoin ────────────────────────────────────────────────

    /// @notice Mint SUSD against already-deposited ETH collateral.
    ///
    /// @dev    MAX MINTABLE FORMULA
    ///         The shop only gives 100/150 of the collateral's dollar value:
    ///
    ///           collateralValueUSD = ethDeposited × ethPrice / PRECISION
    ///           maxMintable        = collateralValueUSD × RATIO_PRECISION
    ///                                / COLLATERAL_RATIO
    ///
    ///         Example: 1 ETH at $2,000:
    ///           collateralValueUSD = 1e18 × 2000e18 / 1e18 = 2000e18
    ///           maxMintable        = 2000e18 × 100 / 150   = 1333.33 SUSD
    ///
    /// @param susdAmount  Amount of SUSD (18 decimals) to mint.
    function mintStablecoin(uint256 susdAmount) external nonReentrant {
        if (susdAmount == 0) revert ZeroAmount();

        uint256 ethPrice = getEthPrice();
        uint256 maxMintable = getMaxMintable(msg.sender, ethPrice);

        // Would minting susdAmount exceed the 150% collateral threshold?
        if (susdMinted[msg.sender] + susdAmount > maxMintable)
            revert ExceedsMaxMintable();

        susdMinted[msg.sender] += susdAmount;
        _mint(msg.sender, susdAmount);

        emit StablecoinMinted(msg.sender, susdAmount);
    }

    // ─── Core: Burn stablecoin & return collateral ─────────────────────────────

    /// @notice Burn SUSD to reduce your minted balance.
    ///         Call this before withdrawCollateral to free up locked ETH.
    ///
    /// @param susdAmount  Amount of SUSD to burn (reduces your debt).
    function burnStablecoin(uint256 susdAmount) external nonReentrant {
        if (susdAmount == 0) revert ZeroAmount();
        if (balanceOf(msg.sender) < susdAmount) revert InsufficientSUSDBalance();

        // Cap: cannot burn more than user has minted via this contract.
        uint256 burnAmount = susdAmount > susdMinted[msg.sender]
            ? susdMinted[msg.sender]
            : susdAmount;

        susdMinted[msg.sender] -= burnAmount;
        _burn(msg.sender, burnAmount);

        emit StablecoinBurned(msg.sender, burnAmount);
    }

    // ─── Core: Withdraw collateral ─────────────────────────────────────────────

    /// @notice Withdraw ETH collateral — only up to the amount that keeps
    ///         your position above the 150% health factor.
    ///
    /// @dev    HEALTH FACTOR CHECK
    ///         After the hypothetical withdrawal, we recompute maxMintable
    ///         against the reduced collateral.  If the user's existing
    ///         susdMinted would exceed the new maxMintable, the withdrawal
    ///         would leave the system under-collateralized → revert.
    ///
    ///         This is the pawn shop refusing to hand back your gold while
    ///         you still owe them store credit you can't cover.
    ///
    /// @param ethAmount  Wei of ETH to withdraw.
    function withdrawCollateral(uint256 ethAmount) external nonReentrant {
        if (ethAmount == 0) revert ZeroAmount();
        if (ethAmount > collateralDeposited[msg.sender])
            revert InsufficientCollateral();

        // ── Health factor check BEFORE executing the withdrawal ────────────────
        uint256 remainingCollateral = collateralDeposited[msg.sender] - ethAmount;

        if (susdMinted[msg.sender] > 0) {
            uint256 ethPrice = getEthPrice();
            // What would maxMintable be with the reduced collateral?
            uint256 remainingCollateralValueUSD =
                (remainingCollateral * ethPrice) / PRECISION;
            uint256 maxMintableAfter =
                (remainingCollateralValueUSD * RATIO_PRECISION) / COLLATERAL_RATIO;

            // If existing debt exceeds the new cap → withdrawal is unsafe.
            if (susdMinted[msg.sender] > maxMintableAfter)
                revert HealthFactorTooLow();
        }

        // ── Safe to proceed ────────────────────────────────────────────────────
        collateralDeposited[msg.sender] = remainingCollateral;

        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        if (!success) revert ETHTransferFailed();

        emit CollateralWithdrawn(msg.sender, ethAmount);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Maximum SUSD a user can mint given their current ETH deposit.
    ///
    /// @dev    maxMintable = (collateralDeposited × ethPrice / PRECISION)
    ///                       × RATIO_PRECISION / COLLATERAL_RATIO
    ///
    /// @param user      Address to check.
    /// @param ethPrice  Normalized 18-decimal ETH price (from getEthPrice()).
    function getMaxMintable(address user, uint256 ethPrice)
        public
        view
        returns (uint256)
    {
        uint256 collateralValueUSD =
            (collateralDeposited[user] * ethPrice) / PRECISION;
        return (collateralValueUSD * RATIO_PRECISION) / COLLATERAL_RATIO;
    }

    /// @notice Returns the user's health factor × 100 (to avoid fractions).
    ///         A value ≥ 100 means the position is safe.
    ///         A value < 100 means the position is under-collateralized.
    ///
    /// @dev    healthFactor = (collateralValueUSD × RATIO_PRECISION)
    ///                        / (susdMinted × COLLATERAL_RATIO / RATIO_PRECISION)
    ///
    ///         Returned as an integer scaled by 100 so callers can check:
    ///           getHealthFactor(user) >= 100  → safe
    function getHealthFactor(address user)
        external
        view
        returns (uint256 healthFactor)
    {
        if (susdMinted[user] == 0) return type(uint256).max; // infinite — no debt

        uint256 ethPrice = getEthPrice();
        uint256 collateralValueUSD =
            (collateralDeposited[user] * ethPrice) / PRECISION;

        // Scale numerator by RATIO_PRECISION² so result is whole-number × 100.
        healthFactor =
            (collateralValueUSD * RATIO_PRECISION * RATIO_PRECISION) /
            (susdMinted[user] * COLLATERAL_RATIO);
    }

    /// @notice Returns collateralDeposited and susdMinted for a user.
    function getPosition(address user)
        external
        view
        returns (uint256 ethCollateral, uint256 mintedSUSD)
    {
        ethCollateral = collateralDeposited[user];
        mintedSUSD    = susdMinted[user];
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    /// @notice Update the Chainlink price feed address (owner only).
    function setPriceFeed(address _newFeed) external onlyOwner {
        if (_newFeed == address(0)) revert InvalidPriceFeed();
        priceFeed = AggregatorV3Interface(_newFeed);
        emit PriceFeedUpdated(_newFeed);
    }

    // ─── Receive ──────────────────────────────────────────────────────────────

    /// @dev Accept plain ETH transfers and credit them as collateral.
    receive() external payable {
        if (msg.value > 0) {
            collateralDeposited[msg.sender] += msg.value;
            emit CollateralDeposited(msg.sender, msg.value);
        }
    }
}
