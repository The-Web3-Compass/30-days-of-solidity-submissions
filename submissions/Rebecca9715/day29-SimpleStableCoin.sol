// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // 基础 ERC20 功能
import "@openzeppelin/contracts/access/Ownable.sol"; // 权限：只有 owner 可以操作
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // 防止重入攻击
import "@openzeppelin/contracts/access/AccessControl.sol"; // 角色权限管理
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // 喂价（预言机）
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

contract SimpleStablecoin is ERC20, Ownable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant PRICE_FEED_MANAGER_ROLE = keccak256("PRICE_FEED_MANAGER_ROLE");
    // 抵押资产，就像保险柜里放的黄金。
    IERC20 public immutable collateralToken;
    // 抵押品的小数位
    uint8 public immutable collateralDecimals;
    // 喂价地址，是实时告诉你黄金价值的价格牌。
    AggregatorV3Interface public priceFeed;
    // 超额抵押率，默认为 150%（1.5 倍）。要多存多少黄金才能换同等面额的稳定币（要多存 1.5 倍，防止价值波动）。
    uint256 public collateralizationRatio = 150; // Expressed as a percentage (150 = 150%)

    event Minted(address indexed user, uint256 amount, uint256 collateralDeposited);
    event Redeemed(address indexed user, uint256 amount, uint256 collateralReturned);
    event PriceFeedUpdated(address newPriceFeed);
    event CollateralizationRatioUpdated(uint256 newRatio);

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

        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        _grantRole(PRICE_FEED_MANAGER_ROLE, _initialOwner);
    }

// 获取当前价格
    function getCurrentPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed response");
        return uint256(price);
    }
// 用户把抵押品存入合约
    function mint(uint256 amount) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();
// 当前抵押品价格
        uint256 collateralPrice = getCurrentPrice();
        uint256 requiredCollateralValueUSD = amount * (10 ** decimals()); // 18 decimals assumed for sUSD
        // 需要抵押品 = （目标铸造 sUSD * 超额抵押率）/ 当前抵押品价格
        uint256 requiredCollateral = (requiredCollateralValueUSD * collateralizationRatio) / (100 * collateralPrice);
        uint256 adjustedRequiredCollateral = (requiredCollateral * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());
// 用户转入抵押品
        collateralToken.safeTransferFrom(msg.sender, address(this), adjustedRequiredCollateral);
        // 合约 _mint 发给用户等值的 sUSD。
        _mint(msg.sender, amount);

        emit Minted(msg.sender, amount, adjustedRequiredCollateral);
    }
// 用户把 sUSD 退回来销毁 → 合约退还相应抵押品。
    function redeem(uint256 amount) external nonReentrant {
        // 是否足额
        if (amount == 0) revert MintAmountIsZero();
        if (balanceOf(msg.sender) < amount) revert InsufficientStablecoinBalance();

        uint256 collateralPrice = getCurrentPrice();
        uint256 stablecoinValueUSD = amount * (10 ** decimals());
        uint256 collateralToReturn = (stablecoinValueUSD * 100) / (collateralizationRatio * collateralPrice);
        uint256 adjustedCollateralToReturn = (collateralToReturn * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());
// 销毁sUSD
        _burn(msg.sender, amount);
        // 转给用户
        collateralToken.safeTransfer(msg.sender, adjustedCollateralToReturn);

        emit Redeemed(msg.sender, amount, adjustedCollateralToReturn);
    }
// Owner 或 Manager 可以修改超额抵押率和喂价来源。
    function setCollateralizationRatio(uint256 newRatio) external onlyOwner {
        if (newRatio < 100) revert CollateralizationRatioTooLow();
        collateralizationRatio = newRatio;
        emit CollateralizationRatioUpdated(newRatio);
    }

    function setPriceFeedContract(address _newPriceFeed) external onlyRole(PRICE_FEED_MANAGER_ROLE) {
        if (_newPriceFeed == address(0)) revert InvalidPriceFeedAddress();
        priceFeed = AggregatorV3Interface(_newPriceFeed);
        emit PriceFeedUpdated(_newPriceFeed);
    }
// 前端展示，想赎回多少 sUSD，可退多少抵押品。
    function getRequiredCollateralForMint(uint256 amount) public view returns (uint256) {
        if (amount == 0) return 0;

        uint256 collateralPrice = getCurrentPrice();
        uint256 requiredCollateralValueUSD = amount * (10 ** decimals());
        uint256 requiredCollateral = (requiredCollateralValueUSD * collateralizationRatio) / (100 * collateralPrice);
        uint256 adjustedRequiredCollateral = (requiredCollateral * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        return adjustedRequiredCollateral;
    }
// 前端展示，想铸造多少，需要存多少抵押品。是一个计算公式的函数
    function getCollateralForRedeem(uint256 amount) public view returns (uint256) {
        if (amount == 0) return 0;

        uint256 collateralPrice = getCurrentPrice();
        uint256 stablecoinValueUSD = amount * (10 ** decimals());
        uint256 collateralToReturn = (stablecoinValueUSD * 100) / (collateralizationRatio * collateralPrice);
        uint256 adjustedCollateralToReturn = (collateralToReturn * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        return adjustedCollateralToReturn;
    }
    
}

// 以下为流程图
// [用户] 
//    │
//    │ 1️⃣ 想要获得 sUSD 稳定币
//    │
//    ▼
// [调用 mint() 函数]
//    │
//    │ - 输入想铸造多少 sUSD
//    │ - 合约调用 Chainlink 喂价获取抵押品实时美元价格
//    │ - 根据当前价格和超额抵押率（如 150%），计算需要存多少抵押品
//    │
//    ▼
// [用户把抵押品转进合约]
//    │
//    │ - 用 `SafeERC20` 安全转账
//    │ - 存入后合约调用 `_mint` 给用户发 sUSD
//    │
//    ▼
// [用户获得 sUSD]
//    │
//    │ - 可以把 sUSD 转给别人、存在钱包、去 DeFi 用
//    │
// ─────────────────────────────

// [用户] 
//    │
//    │ 2️⃣ 想要赎回抵押品
//    │
//    ▼
// [调用 redeem() 函数]
//    │
//    │ - 输入要销毁多少 sUSD
//    │ - 合约调用喂价获取抵押品实时美元价格
//    │ - 计算能退多少抵押品（按超额抵押比例）
//    │
//    ▼
// [合约销毁用户 sUSD]
//    │
//    │ - `_burn` 从用户账户扣除 sUSD
//    │ - 把等值的抵押品退给用户
//    │
//    ▼
// [用户拿回抵押品]
//    │
// ─────────────────────────────

// [管理员] 
//    │
//    │ 3️⃣ 调整参数
//    │
//    ▼
// [调用 setCollateralizationRatio()]
//    │
//    │ - 改变超额抵押率（比如从 150% 改 200%）
//    │
// ─────────────────────────────

// [管理员]
//    │
//    │ 4️⃣ 更新喂价
//    │
//    ▼
// [调用 setPriceFeedContract()]
//    │
//    │ - 换新的预言机（喂价）合约地址
//    │
// ─────────────────────────────

