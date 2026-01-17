//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Real-world stablecoins: collateralized reserves,on-chain and off-chain oracles,dynamic supply adjustments,governance votes and full audits and legal compliance.
// This contract aims to build simplified version of stable coin: mint coins, redeem coins, retrieve coins with real collateral and calculate safe margins and protect the system.

// Work flow:
// 1. Users deposit a trusted token as collateral and the system would mint coins whose quantity is based on the latest price from a price feed.
// 2. Users always deposit more collateral than the value of stablecoins they're getting.
// 3. Users can redeem stablecoins back by burning coins if they want their collateral back.


// Standard functionality:mint,transfer and manage balances.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// It is a safety net for dealing with other ERC-20 tokens.
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// Define custom roles and accurately control who can call certain functions.
import "@openzeppelin/contracts/access/AccessControl.sol";
// Help us fetch extra information about the collateral token.
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SimpleStablecoin is ERC20,Ownable,ReentrancyGuard,AccessControl{
    // This line activates SafeERC20 for all IERC20 tokens we interact with.
    using SafeERC20 for IERC20;

    // Create a special role called "PRICE_FEED_MANAGER_ROLE" which controls who can update the price feed.
    // "keccak256" for bytes variables so the role has a unique and cryptographically strong identifier.
    bytes32 public constant PRICE_FEED_MANAGER_ROLE=keccak256("PRICE_FEED_MANAGER_ROLE");
    IERC20 public immutable collateralToken;
    uint8 public immutable collateralDecimals;
    AggregatorV3Interface public priceFeed;
    // Set the collateralization ratio : it means that users must always deposit 150% worth of collateral for the stable coins they mint.
    uint256 public collateralizationRatio=150;

    event Minted(address indexed user,uint256 amount,uint256 collateralDeposited);
    event Redeemed(address indexed user,uint256 amount,uint256 collateralReturned);
    event PriceFeedUpdated(address newPriceFeed);
    event CollateralizationRatioUpdated(uint256 newRatio);

    error InvalidCollateralTokenAddress();
    error InvalidPriceFeedAddress();
    error MintAmountIsZero();
    error InsufficientStablecoinBalance();
    error CollateralizationRatioTooLow();

    constructor(address _collateralToken,address _initialOwner,address _priceFeed)ERC20("Simple USD stablecoin","sUSD") Ownable(_initialOwner){
        if(_collateralToken==address(0) )revert InvalidCollateralTokenAddress();
        if(_priceFeed==address(0)) revert InvalidPriceFeedAddress();

        collateralToken=IERC20(_collateralToken);
        collateralDecimals=IERC20Metadata(_collateralToken).decimals();
        priceFeed=AggregatorV3Interface(_priceFeed);

        // Give the owner full control over the contract's role system.
        _grantRole(DEFAULT_ADMIN_ROLE,_initialOwner);
        // Lets the owner update the price feed if needed in the future.
        _grantRole(PRICE_FEED_MANAGER_ROLE,_initialOwner);
    }

    function getCurrentPrice() public view returns (uint256){
        (,int256 price,,,)=priceFeed.latestRoundData();
        require(price>0,"Invalid price feed response");
        return uint256(price);
    }

    function mint(uint256 amount) external nonReentrant{
        if(amount==0) revert MintAmountIsZero();
        
        uint256 collateralPrice=getCurrentPrice();
        // Calculate the USD value of the stablecoins the user want to mint.
        uint256 requiredCollateralValueUSD=amount*(10**decimals());
        uint256 requiredCollateral=(requiredCollateralValueUSD*collateralizationRatio)/(100*collateralPrice);
        // Adjust the numbers here to make sure the calculation is precision-correct for both the collateral token and the price feed.
        uint256 adjustedRequiredCollateral=(requiredCollateral*(10**collateralDecimals))/(10**priceFeed.decimals());

        collateralToken.safeTransferFrom(msg.sender,address(this),adjustedRequiredCollateral);
        _mint(msg.sender,amount);

        emit Minted(msg.sender,amount,adjustedRequiredCollateral);

    }

    function redeem(uint256 amount) external nonReentrant{
        if(amount==0) revert MintAmountIsZero();
        if(balanceOf(msg.sender)<amount) revert InsufficientStablecoinBalance();

        uint256 collateralPrice=getCurrentPrice();
        uint256 stablecoinValueUSD=amount*(10**decimals());
        uint256 collateralToReturn=(stablecoinValueUSD*100)/(collateralizationRatio*collateralPrice);
        uint256 adjustedCollateralToReturn=(collateralToReturn*(10**collateralDecimals))/(10**priceFeed.decimals());

        _burn(msg.sender,amount);
        collateralToken.safeTransfer(msg.sender,adjustedCollateralToReturn);

        emit Redeemed(msg.sender,amount,adjustedCollateralToReturn);

    }

    function setCollateralizationRatio(uint256 newRatio) external onlyOwner{
        if(newRatio<100) revert CollateralizationRatioTooLow();
        collateralizationRatio=newRatio;
        emit CollateralizationRatioUpdated(newRatio);
    }

    function setPriceFeedContract(address _newPriceFeed) external onlyRole(PRICE_FEED_MANAGER_ROLE){
        if(_newPriceFeed==address(0)) revert InvalidPriceFeedAddress();
        priceFeed=AggregatorV3Interface(_newPriceFeed);
        emit PriceFeedUpdated(_newPriceFeed);
    }

    // Before a user call "mint", it's helpful to know exactly how much collateral they will need to deposit.
    function getRequiredCollateralForMint(uint256 amount) public view returns(uint256){
        if(amount==0) return 0;

        uint256 collateralPrice=getCurrentPrice();
        uint256 requiredCollateralValueUSD=amount*(10**decimals());
        uint256 requiredCollateral=(requiredCollateralValueUSD*collateralizationRatio)/(100*collateralPrice);
        uint256 adjustedRequiredCollateral=(requiredCollateral*(10**collateralDecimals))/(10**priceFeed.decimals());

        return adjustedRequiredCollateral;

    }

    // It helps users check how much collateral they will receive if they redeem a certain amount of USD.
    function getCollateralForRedeem(uint256 amount) public view returns (uint256){
        if(amount==0) return 0;

        uint256 collateralPrice=getCurrentPrice();
        uint256 stablecoinValueUSD=amount*(10**decimals());
        uint256 collateralToReturn=(stablecoinValueUSD*100)/(collateralizationRatio*collateralPrice);
        uint256 adjustedCollateralToReturn=(collateralToReturn*(10**collateralDecimals))/(10**priceFeed.decimals());
        return adjustedCollateralToReturn;

    }


}