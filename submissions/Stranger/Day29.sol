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
    // 对IERC20 类型激活SafeERC20, 对transer及transferFrom这样的方法自动启用安全检查包装, 确保代币操作要么成功要么安全回滚
    using SafeERC20 for IERC20;

    // 创建角色来控制谁可以更新价格源
    bytes32 public constant PRICE_FEED_MANAGER_ROLE = keccak256("PRICE_FEED_MANAGER_ROLE");
    // 作为抵押品的代币地址, immutable 确保它只能设置一次后面永远不能修改
    IERC20 public immutable collateralToken;
    // 作为抵押品的代币的精度
    uint8 public immutable collateralDecimals;
    // Chainlink 价格源
    AggregatorV3Interface public priceFeed;
    // 抵押率, 例如150表示铸造100个稳定币需要150/100=1.5倍的价值的抵押品
    uint256 public collateralizationRatio = 150; // 以百分比表示（150 = 150%）

    // 定义4类事件: 铸币, 赎回稳定币, 价格源地址更新事件, 抵押率更新事件
    event Minted(address indexed user, uint256 amount, uint256 collateralDeposited);
    event Redeemed(address indexed user, uint256 amount, uint256 collateralReturned);
    event PriceFeedUpdated(address newPriceFeed);
    event CollateralizationRatioUpdated(uint256 newRatio);

    // 自定义错误比require更便宜(gas)更易读
    error InvalidCollateralTokenAddress();
    error InvalidPriceFeedAddress();
    error MintAmountIsZero();
    error InsufficientStablecoinBalance();
    error CollateralizationRatioTooLow();

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

        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);      // 默认管理员, 这应该是内置角色
        _grantRole(PRICE_FEED_MANAGER_ROLE, _initialOwner); // 价格源管理员
    }

    // 获取实时价格, 代币/USD的价格流, 即1代币可兑多少个USD, 返回值包含了代币的精度
    // 例如对于eth/usd的价格流，返回值需要再除以10**18, 即为1eth可兑多少美元
    function getCurrentPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed response");
        return uint256(price);
    }

    // 铸造稳定币
    function mint(uint256 amount) external nonReentrant {
        // 要铸造的稳定币的数量, 铸造0个稳定币只会浪费gas
        if (amount == 0) revert MintAmountIsZero();

        // 抵押代币最新的以美元计价的价值
        uint256 collateralPrice = getCurrentPrice();
        uint256 adjustedRequiredCollateral = amount * (10 ** collateralDecimals) * collateralizationRatio * (10 ** priceFeed.decimals()) / (100 * collateralPrice);
        /*
        // 要铸造的稳定币的价值(已调整为sUSD的精度)
        uint256 requiredCollateralValueUSD = amount * (10 ** decimals());
        // 所需抵押品的价值(已调整为sUSD的精度)
        uint256 requiredCollateral = (requiredCollateralValueUSD * collateralizationRatio) / (100 * collateralPrice);
        // 调整精度, 抵押币的价值
        uint256 adjustedRequiredCollateral = (requiredCollateral * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());
        */

        collateralToken.safeTransferFrom(msg.sender, address(this), adjustedRequiredCollateral);
        _mint(msg.sender, amount);

        // 触发事件, 返回铸币人, 铸币个数(非高精度), 抵押品数量(高精度)
        emit Minted(msg.sender, amount, adjustedRequiredCollateral);
    }

    // 赎回稳定币
    function redeem(uint256 amount) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();
        if (balanceOf(msg.sender) < amount) revert InsufficientStablecoinBalance();

        uint256 collateralPrice = getCurrentPrice();
        uint256 stablecoinValueUSD = amount * (10 ** decimals());
        uint256 collateralToReturn = (stablecoinValueUSD * 100) / (collateralizationRatio * collateralPrice);
        uint256 adjustedCollateralToReturn = (collateralToReturn * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        _burn(msg.sender, amount);
        collateralToken.safeTransfer(msg.sender, adjustedCollateralToReturn);

        emit Redeemed(msg.sender, amount, adjustedCollateralToReturn);
    }

    // 设置抵押率
    function setCollateralizationRatio(uint256 newRatio) external onlyOwner {
        if (newRatio < 100) revert CollateralizationRatioTooLow();
        collateralizationRatio = newRatio;
        emit CollateralizationRatioUpdated(newRatio);
    }
    // 设置价格源
    function setPriceFeedContract(address _newPriceFeed) external onlyRole(PRICE_FEED_MANAGER_ROLE) {
        if (_newPriceFeed == address(0)) revert InvalidPriceFeedAddress();
        priceFeed = AggregatorV3Interface(_newPriceFeed);
        emit PriceFeedUpdated(_newPriceFeed);
    }

    // 查询铸币所需的抵押品价值
    function getRequiredCollateralForMint(uint256 amount) public view returns (uint256) {
        if (amount == 0) return 0;

        uint256 collateralPrice = getCurrentPrice();
        /*
        uint256 requiredCollateralValueUSD = amount * (10 ** decimals());
        uint256 requiredCollateral = (requiredCollateralValueUSD * collateralizationRatio) / (100 * collateralPrice);
        uint256 adjustedRequiredCollateral = (requiredCollateral * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());
        */
        uint256 adjustedRequiredCollateral = amount * (10 ** collateralDecimals) * collateralizationRatio * (10 ** priceFeed.decimals()) / (100 * collateralPrice);

        return adjustedRequiredCollateral;
    }

    // 查询赎回时返回的抵押品数量
    function getCollateralForRedeem(uint256 amount) public view returns (uint256) {
        if (amount == 0) return 0;

        uint256 collateralPrice = getCurrentPrice();
        uint256 stablecoinValueUSD = amount * (10 ** decimals());
        uint256 collateralToReturn = (stablecoinValueUSD * 100) / (collateralizationRatio * collateralPrice);
        uint256 adjustedCollateralToReturn = (collateralToReturn * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        return adjustedCollateralToReturn;
    }

}

