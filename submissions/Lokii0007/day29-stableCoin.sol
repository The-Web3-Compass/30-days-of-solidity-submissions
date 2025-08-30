// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SimpleStableCoin is ERC20, Ownable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    bytes32 public constant PRICE_FEED_MANAGER_ROLE =
        keccak256("PRICE_FEED_MANAGER_ROLE");
    IERC20 public immutable collateralToken;
    uint8 public immutable collateralDecimals;
    AggregatorV3Interface public priceFeed;
    uint public collateralizationRatio = 150;

    event Minted(address indexed user, uint amoount, uint collateralDeposit);
    event Reedemed(address indexed user, uint amoount, uint collateralReturned);
    event PriceFeedUpdated(address newPriceFeed);
    event CollateralRationUpdated(uint newRatio);

    error InvalidCollateralTokenAddress();
    error InvalidPriceFeedAddress();
    error MintAmountIsZero();
    error InsufficientStableCoinBalance();
    error CollateralizationRatioTooLow();

    constructor(
        address _collateralToken,
        address _priceFeed,
        address _initalOwner
    ) ERC20("Simple stablecoin", "STC") Ownable(_initalOwner) {
        if (_collateralToken == address(0))
            revert InvalidCollateralTokenAddress();
        if (_priceFeed == address(0)) revert InvalidPriceFeedAddress();

        collateralToken = IERC20(_collateralToken);
        collateralDecimals = IERC20Metadata(_collateralToken).decimals();
        priceFeed = AggregatorV3Interface(_priceFeed);

        _grantRole(DEFAULT_ADMIN_ROLE, _initalOwner);
        _grantRole(PRICE_FEED_MANAGER_ROLE, _initalOwner);
    }

    function getCurrentPrice() public view returns(uint256) {
       (, int256 price,,,) = priceFeed.latestRoundData();
       require(price > 0, "price must be greater than 0");
       return uint(price);
    }

    function mint(uint _amount) external nonReentrant {
        if(_amount == 0 ) revert MintAmountIsZero();

        uint collateralPriceUSD = getCurrentPrice();
        uint stablecoinScaleFactor = collateralPriceUSD * 10 ** decimals(); //* to match stable coin decimals
        uint requiredCollateralInUSD = (stablecoinScaleFactor * collateralizationRatio)/(100 * collateralPriceUSD);
        uint requiredCollateralTokens = (requiredCollateralInUSD * (10 ** collateralDecimals) )/(10 ** priceFeed.decimals());

        collateralToken.safeTransferFrom(msg.sender, address(this), requiredCollateralTokens);
        _mint(msg.sender, _amount);

        emit Minted(msg.sender, _amount, requiredCollateralTokens);
    }

    function reedem(uint _amount) external nonReentrant {
        if(_amount == 0 ) revert MintAmountIsZero();
        if( balanceOf(msg.sender) < _amount ) revert InsufficientStableCoinBalance();

        uint collateralPriceUSD = getCurrentPrice();
        uint stablecoinScaleFactor = collateralPriceUSD * 10 ** decimals(); //* to match stable coin decimals
        uint collateralToReturnInUSD = (stablecoinScaleFactor * 100)/(collateralizationRatio * collateralPriceUSD);
        uint CollateralTokensToReturn = (collateralToReturnInUSD * (10 ** collateralDecimals) )/(10 ** priceFeed.decimals());

        collateralToken.safeTransfer(msg.sender, CollateralTokensToReturn);
        _burn(msg.sender, _amount);

        emit Reedemed(msg.sender, _amount, CollateralTokensToReturn);
    }

    function setCollaterlizationRatio(uint _newRatio) external onlyOwner{
        if(_newRatio < 100) revert CollateralizationRatioTooLow();
        collateralizationRatio = _newRatio;

        emit CollateralRationUpdated(_newRatio);
    }

    function setPriceFeedContract(address _newPriceFeed) external onlyRole(PRICE_FEED_MANAGER_ROLE){
        if(_newPriceFeed == address(0)) revert InvalidPriceFeedAddress();
        priceFeed = AggregatorV3Interface(_newPriceFeed);

        emit PriceFeedUpdated(_newPriceFeed);
    }

    function getRequiredCollateral(uint _amount) public view returns(uint){
        if(_amount == 0 ) return 0;

        uint collateralPriceUSD = getCurrentPrice();
        uint stablecoinScaleFactor = collateralPriceUSD * 10 ** decimals(); //* to match stable coin decimals
        uint requiredCollateralInUSD = (stablecoinScaleFactor * collateralizationRatio)/(100 * collateralPriceUSD);
        uint requiredCollateralTokens = (requiredCollateralInUSD * (10 ** collateralDecimals) )/(10 * priceFeed.decimals());

        return requiredCollateralTokens;
    }

    function getCollateralReedem(uint _amount) public view returns(uint) {
        if(_amount == 0 ) return 0;

        uint collateralPriceUSD = getCurrentPrice();
        uint stablecoinScaleFactor = collateralPriceUSD * 10 ** decimals(); //* to match stable coin decimals
        uint collateralToReturnInUSD = (stablecoinScaleFactor * 100)/(collateralizationRatio * collateralPriceUSD);
        uint CollateralTokensToReturn = (collateralToReturnInUSD * (10 ** collateralDecimals) )/(10 * priceFeed.decimals());

        return CollateralTokensToReturn;
    }
}
