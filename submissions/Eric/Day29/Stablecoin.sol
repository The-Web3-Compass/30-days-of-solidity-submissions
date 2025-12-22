// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/** 
 * @title StableCoin.sol
 * @author Eric (https://github.com/0xxEric)
 * @notice Simplified collateral-backed stablecoin.
 - Uses an ERC20 collateral token (e.g. WETH).
 - Uses a price oracle (IPriceOracle) to get collateral USD price.
 - mintWithCollateral: user deposits collateral -> mints stablecoin at current rate minus fee.
 - redeem: user burns stablecoin -> receives collateral based on oracle price minus fee.
 * @dev This is a minimal prototype. 
*/


import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface IPriceOracle {
    // returns price of 1 unit of collateral in USD with 18 decimals (e.g. 1 collateral = 2000 * 1e18 USD)
    function getPrice() external view returns (uint256);
}

contract CollateralStablecoin is ERC20, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable collateralToken;
    IPriceOracle public priceOracle;

    // Fees in basis points (bps). e.g. 50 = 0.5%
    uint256 public mintFeeBps = 50;
    uint256 public redeemFeeBps = 50;

    // min collateralization ratio in percent (e.g. 150 -> 150%)
    uint256 public minCollateralRatio = 150;

    // Track collateral held by contract
    uint256 public totalCollateral; // collateral token units (raw decimals)

    event Minted(address indexed user, uint256 collateralIn, uint256 stableOut);
    event Redeemed(address indexed user, uint256 stableIn, uint256 collateralOut);
    event OracleUpdated(address indexed newOracle);
    event FeesUpdated(uint256 mintFeeBps, uint256 redeemFeeBps);
    event CollateralRatioUpdated(uint256 minCollateralRatio);

    constructor(
        address _collateralToken,
        address _oracle,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        require(_collateralToken != address(0), "zero collateral");
        require(_oracle != address(0), "zero oracle");
        collateralToken = IERC20(_collateralToken);
        priceOracle = IPriceOracle(_oracle);
    }

    // Helper: convert collateralAmount -> USD value (18 decimals)
    function collateralToUSD(uint256 collateralAmount) public view returns (uint256) {
        // assume collateralToken has decimals 'd', but we treat values in token raw units.
        // Oracle returns price (USD per 1 collateral) with 18 decimals.
        // result = collateralAmount * price / (10**collateralDecimals)
        uint8 d = ERC20(address(collateralToken)).decimals();
        uint256 price = priceOracle.getPrice(); // 1 collateral = price (USD*1e18)
        return (collateralAmount * price) / (10 ** d);
    }

    // Helper: convert USD(18) amount -> collateral units (raw)
    function usdToCollateral(uint256 usdAmount) public view returns (uint256) {
        uint8 d = ERC20(address(collateralToken)).decimals();
        uint256 price = priceOracle.getPrice();
        // collateral = usdAmount * 10^decimals / price
        return (usdAmount * (10 ** d)) / price;
    }

    // Mint stablecoin by depositing collateral.
    // The stablecoin peg assumed is 1 USD per stable token (with 18 decimals).
    function mintWithCollateral(uint256 collateralAmount) external nonReentrant {
        require(collateralAmount > 0, "zero collateral");
        // transfer collateral in
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        totalCollateral += collateralAmount;

        // compute USD value of collateral
        uint256 usdValue = collateralToUSD(collateralAmount); // (USD * 1e18)
        // fee
        uint256 fee = (usdValue * mintFeeBps) / 10000;
        uint256 usdAfterFee = usdValue - fee;

        // mint stable tokens: assume stable coin has 18 decimals and 1 stable = 1 USD
        uint256 stableToMint = usdAfterFee / (1e0); // usdValue already 1e18 scale; ERC20 has 1e18 decimals so it's fine
        // ensure over-collateralization if desired (this simple example doesn't require extra)
        _mint(msg.sender, stableToMint);

        emit Minted(msg.sender, collateralAmount, stableToMint);
    }

    // Redeem stable tokens to get collateral back
    function redeem(uint256 stableAmount) external nonReentrant {
        require(stableAmount > 0, "zero stable");
        // burn stable from user
        _burn(msg.sender, stableAmount);

        // compute required collateral to cover stableAmount
        // stableAmount (18 decimals) -> USD value is stableAmount * 1 (1 stable = $1)
        uint256 usdValue = stableAmount; // already 1e18 scale; if stable decimals differ adjust
        // fee
        uint256 fee = (usdValue * redeemFeeBps) / 10000;
        uint256 usdAfterFee = usdValue - fee;

        uint256 collateralOut = usdToCollateral(usdAfterFee);
        require(collateralOut <= totalCollateral, "insufficient collateral in pool");

        totalCollateral -= collateralOut;
        collateralToken.safeTransfer(msg.sender, collateralOut);

        emit Redeemed(msg.sender, stableAmount, collateralOut);
    }

    // Owner functions to tune parameters
    function setPriceOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "zero");
        priceOracle = IPriceOracle(_oracle);
        emit OracleUpdated(_oracle);
    }

    function setFees(uint256 _mintFeeBps, uint256 _redeemFeeBps) external onlyOwner {
        require(_mintFeeBps <= 1000 && _redeemFeeBps <= 1000, "fee too large"); // max 10%
        mintFeeBps = _mintFeeBps;
        redeemFeeBps = _redeemFeeBps;
        emit FeesUpdated(_mintFeeBps, _redeemFeeBps);
    }

    function setMinCollateralRatio(uint256 _ratioPercent) external onlyOwner {
        require(_ratioPercent >= 100, "ratio too low");
        minCollateralRatio = _ratioPercent;
        emit CollateralRatioUpdated(_ratioPercent);
    }

    // Emergency withdraw of dust (owner only) - for prototype only
    function ownerWithdrawCollateral(uint256 amount, address to) external onlyOwner {
        require(amount <= totalCollateral, "too much");
        totalCollateral -= amount;
        collateralToken.safeTransfer(to, amount);
    }
}
