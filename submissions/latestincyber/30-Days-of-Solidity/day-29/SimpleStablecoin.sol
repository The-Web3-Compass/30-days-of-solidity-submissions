// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract SimpleStablecoin is ERC20, ReentrancyGuard, Ownable {
    // 1. the oracle (to know the price of ETH)
    AggregatorV3Interface internal priceFeed;

    // 2. collateralization ratio and liquidation penalty
    uint256 public constant COLLATERALIZATION_RATIO = 150; // 150%
    uint256 public constant LIQUIDATION_PENALTY = 10; // 10% penalty on liquidation

    // 3. user -> amount of ETH deposited
    mapping(address => uint256) public collateralDeposited;

    constructor(address _priceFeedAddress) ERC20("StableUSD", "SUSD") Ownable(msg.sender) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // MAIN FUNCTIONS

    function depositCollateral() external payable {
        collateralDeposited[msg.sender] += msg.value;
    }

    function mintStablecoin(uint256 amountToMint) external nonReentrant {
        uint256 currentEthValue = getCollateralValueInUsd(msg.sender);
        uint256 currentDebt = balanceOf(msg.sender);

        // check health factor
        uint256 maxMintable = (currentEthValue * 100) / COLLATERALIZATION_RATIO; // max mintable based on collateral
        require(currentDebt + amountToMint <= maxMintable, "Not enough collateral!");

        _mint(msg.sender, amountToMint);
    }

    function burnStablecoin(uint256 amountToBurn) external nonReentrant {
        _burn(msg.sender, amountToBurn);
    }

    function withdrawCollateral(uint256 amount) external nonReentrant {
        uint256 currentDebt = balanceOf(msg.sender);

        // calculate remaining collateral AFTER withdrawal
        uint256 remainingCollateral = collateralDeposited[msg.sender] - amount;
        uint256 remainingValue = (remainingCollateral * getEthPrice()) / 1e18; // price is 8 decimals usually but
        // let's assume standard formatting for tutorial simplicity
        uint256 requiredCollateralValue = (currentDebt * COLLATERALIZATION_RATIO) / 100;

        require(remainingValue >= requiredCollateralValue, "Cannot withdraw, health factor too low!");

        collateralDeposited[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    // ORACLE MAGIC
    
    function getEthPrice() public view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        // chainlink returns price with 8 decimals (e.g. 200000000000 for $2000)
        // we want everything in 18 decimals like ETH
        return uint256(price) * 1e10;
    }

    function getCollateralValueInUsd(address user) public view returns (uint256) {
        uint256 ethAmount = collateralDeposited[user];
        uint256 ethPrice = getEthPrice();
        // (ETH amount * price) / 1e18
        return (ethAmount * ethPrice) / 1e18;
    }

    function liquidate(address user) external nonReentrant {
        uint256 collateralValue = getCollateralValueInUsd(user);
        uint256 debtValue = balanceOf(user);
        if (debtValue == 0) return; // no debt, no liquidation

        uint256 healthFactor = (collateralValue * 100) / debtValue;

        require(healthFactor < COLLATERALIZATION_RATIO, "Position is healthy, cannot liquidate");

        // liquidator pays debt, gets collateral + bonus
        uint256 bonusCollateral = (collateralDeposited[user] * LIQUIDATION_PENALTY) / 100; // 10% bonus
        uint256 collateralToTransfer = collateralDeposited[user] + bonusCollateral;

        _burn(msg.sender, debtValue);
        collateralDeposited[user] = 0; // reset user's collateral

        // cap the transfer to what is avail + bonus logic (simplified here to dump all collateral for full debt repayment)
        // in a real system you'd calculate exact amounts to cover debt + buffer
        (bool success, ) = payable(msg.sender).call{value: collateralToTransfer}("");
        require(success, "Transfer failed");
    }
}