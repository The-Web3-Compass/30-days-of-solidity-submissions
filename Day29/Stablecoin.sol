// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Stablecoin
 * @dev A simple collateralized stablecoin example pegged to USD.
 * Users deposit ETH as collateral and mint a USD-pegged token.
 * Demonstrates basic peg maintenance using over-collateralization.
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Stablecoin is ERC20 {
    // -------------------------
    // STATE VARIABLES
    // -------------------------
    AggregatorV3Interface internal priceFeed; // ETH/USD price oracle
    address public owner;

    uint256 public collateralRatio = 150; // 150% collateral requirement
    mapping(address => uint256) public collateralBalance; // ETH collateral per user

    // -------------------------
    // EVENTS
    // -------------------------
    event CollateralDeposited(address indexed user, uint256 amount);
    event TokensMinted(address indexed user, uint256 amount);
    event TokensRedeemed(address indexed user, uint256 amount, uint256 ethReturned);

    // -------------------------
    // CONSTRUCTOR
    // -------------------------
    constructor(address _priceFeed) ERC20("MyStablecoin", "MSC") {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // -------------------------
    // CORE FUNCTIONS
    // -------------------------

    /**
     * @notice Deposit ETH as collateral and mint stablecoins.
     */
    function depositCollateral() external payable {
        require(msg.value > 0, "Must send ETH");

        // Update collateral balance
        collateralBalance[msg.sender] += msg.value;

        // Get current ETH/USD price
        uint256 ethPrice = getEthUsdPrice();

        // Calculate how many tokens can be minted
        uint256 usdValue = (msg.value * ethPrice) / 1e18; // value in USD (scaled)
        uint256 mintAmount = (usdValue * 1e18) / collateralRatio; // account for 150% collateral

        _mint(msg.sender, mintAmount);

        emit CollateralDeposited(msg.sender, msg.value);
        emit TokensMinted(msg.sender, mintAmount);
    }

    /**
     * @notice Redeem stablecoins for ETH based on current price.
     * @param tokenAmount Amount of tokens to redeem.
     */
    function redeem(uint256 tokenAmount) external {
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");

        uint256 ethPrice = getEthUsdPrice();

        // USD value of tokens
        uint256 usdValue = (tokenAmount * 1e18) / 1e18;
        uint256 ethAmount = (usdValue * 1e18) / ethPrice;

        // Ensure user has enough collateral
        require(collateralBalance[msg.sender] >= ethAmount, "Not enough collateral");

        // Update balances
        _burn(msg.sender, tokenAmount);
        collateralBalance[msg.sender] -= ethAmount;

        // Transfer ETH back to user
        payable(msg.sender).transfer(ethAmount);

        emit TokensRedeemed(msg.sender, tokenAmount, ethAmount);
    }

    // -------------------------
    // PRICE ORACLE
    // -------------------------

    /**
     * @notice Fetch latest ETH/USD price from Chainlink.
     */
    function getEthUsdPrice() public view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        // Chainlink returns 8 decimals, convert to 18 decimals
        return uint256(price) * 1e10;
    }

    // -------------------------
    // ADMIN FUNCTIONS
    // -------------------------
    function setCollateralRatio(uint256 _ratio) external onlyOwner {
        require(_ratio >= 100, "Collateral must be >= 100%");
        collateralRatio = _ratio;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // -------------------------
    // FALLBACK
    // -------------------------
    receive() external payable {}
}
