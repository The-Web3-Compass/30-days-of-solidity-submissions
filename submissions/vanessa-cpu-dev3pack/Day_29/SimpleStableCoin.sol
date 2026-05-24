// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SimpleStablecoin is ERC20, ReentrancyGuard, Ownable {
    // 1. The Oracle (To know the price of ETH)
    AggregatorV3Interface internal priceFeed;

    // 2. The Ratio (150% Collateral needed)
    uint256 public constant COLLATERAL_RATIO = 150; 

    // User -> Amount of ETH deposited
    mapping(address => uint256) public collateralDeposited;

    constructor(address _priceFeedAddress) ERC20("StableUSD", "SUSD") {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // --- MAIN FUNCTIONS ---

    function depositCollateral() external payable {
        collateralDeposited[msg.sender] += msg.value;
    }

    function mintStablecoin(uint256 amountToMint) external nonReentrant {
        uint256 currentEthValue = getCollateralValueInUsd(msg.sender);
        uint256 currentDebt = balanceOf(msg.sender);
        
        // Check health factor
        uint256 maxMintable = (currentEthValue * 100) / COLLATERAL_RATIO;
        require(currentDebt + amountToMint <= maxMintable, "Not enough collateral!");

        _mint(msg.sender, amountToMint);
    }

    function burnStablecoin(uint256 amountToBurn) external nonReentrant {
        _burn(msg.sender, amountToBurn);
    }

    function withdrawCollateral(uint256 amount) external nonReentrant {
        uint256 currentDebt = balanceOf(msg.sender);
        
        // Calculate remaining collateral value AFTER withdrawal
        uint256 remainingCollateral = collateralDeposited[msg.sender] - amount;
        uint256 remainingValue = (remainingCollateral * getEthPrice()) / 1e18; // Price is 8 decimals usually, but let's assume standard formatting for tutorial simplicity

        uint256 requiredCollateralValue = (currentDebt * COLLATERAL_RATIO) / 100;

        require(remainingValue >= requiredCollateralValue, "Cannot withdraw, health factor too low");

        collateralDeposited[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // --- ORACLE MAGIC ---
    
    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Chainlink returns price with 8 decimals (e.g. 200000000000 for $2000)
        // We want everything in 18 decimals like ETH
        if (price < 0) return 0;
        return uint256(price) * 1e10; 
    }

    function getCollateralValueInUsd(address user) public view returns (uint256) {
        uint256 ethAmount = collateralDeposited[user];
        uint256 ethPrice = getEthPrice();
        // (ETH Amount * Price) / 1e18
        return (ethAmount * ethPrice) / 1e18;
    }

    function liquidate(address user) external nonReentrant {
        uint256 collateralValue = getCollateralValueInUsd(user);
        uint256 debtValue = balanceOf(user);
        if (debtValue == 0) return;

        uint256 healthFactor = (collateralValue * 100) / debtValue;
        
        require(healthFactor < COLLATERAL_RATIO, "Position is healthy");
        
        // Liquidator pays debt, gets collateral + bonus
        uint256 liquidationBonus = collateralDeposited[user] * 5 / 100; // 5% bonus
        
        _burn(msg.sender, debtValue);
        uint256 collateralToTransfer = collateralDeposited[user];
        collateralDeposited[user] = 0;
        
        // Cap the transfer to what is available plus bonus logic (simplified here to just dump all collateral for full debt repayment)
        // In a real system you'd calculate exact amounts to cover debt + buffer
        payable(msg.sender).transfer(collateralToTransfer);
    }
}