// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";//导入代币合约
import "@openzeppelin/contracts/access/Ownable.sol";//合约所有者
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";//重入"的攻击
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";//ERC-20 代币的安全网
import "@openzeppelin/contracts/access/AccessControl.sol";//价格源管理器 角色
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";//它使用多少位小数
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";// Chainlink 导入 AggregatorV3Interface

contract SimpleStablecoin is ERC20, Ownable, ReentrancyGuard, AccessControl {//扩展四个强大的 OpenZeppelin 合约以继承现成的功能
    using SafeERC20 for IERC20;//与之交互的所有 IERC20 代币激活 SafeERC20

    bytes32 public constant PRICE_FEED_MANAGER_ROLE = keccak256("PRICE_FEED_MANAGER_ROLE");
    //创建一个名为 PRICE_FEED_MANAGER_ROLE 的特殊角色，它控制谁可以更新价格源
    IERC20 public immutable collateralToken;//作为抵押品存入的 ERC-20 代币的地址
    uint8 public immutable collateralDecimals;//不同的 ERC-20 代币可以有不同数量的小数
    AggregatorV3Interface public priceFeed;// Chainlink 价格源 合约
    uint256 public collateralizationRatio = 150; // 抵押率以百分比表示（150 = 150%）

    event Minted(address indexed user, uint256 amount, uint256 collateralDeposited);
    //当有人成功铸造新稳定币时，就会触发此事件
    event Redeemed(address indexed user, uint256 amount, uint256 collateralReturned);
    //当有人将稳定币赎回为抵押品时，就会触发此事件
    event PriceFeedUpdated(address newPriceFeed);//表示价格源地址已更新
    event CollateralizationRatioUpdated(uint256 newRatio);//每当抵押率被更改时，就会发出此事件

    error InvalidCollateralTokenAddress();//如果有人试图用无效（零）抵押代币地址部署合约，就会抛出此错误
    error InvalidPriceFeedAddress();//如果提供的价格源地址无效，就会触发此错误
    error MintAmountIsZero();//如果用户试图铸造零稳定币，我们抛出此错误
    error InsufficientStablecoinBalance();//当用户试图赎回比他们实际余额更多的稳定币时，使用此错误。
    error CollateralizationRatioTooLow();//如果有人试图将抵押率设置为低于 100%，就会抛出此错误。

    constructor(
        address _collateralToken,//抵押代币的地址（像 USDC、WETH 等 ERC-20）
        address _initialOwner,//初始所有者的地址（管理员）
        address _priceFeed//Chainlink 价格源的地址（获取实时抵押品价格
    ) ERC20("Simple USD Stablecoin", "sUSD") Ownable(_initialOwner) {
        if (_collateralToken == address(0)) revert InvalidCollateralTokenAddress();//检查提供的抵押代币地址是有效的（不是零地址）
        if (_priceFeed == address(0)) revert InvalidPriceFeedAddress();//确保 Chainlink 价格源地址在继续之前是有效的

        collateralToken = IERC20(_collateralToken);//保存抵押代币的地址
        collateralDecimals = IERC20Metadata(_collateralToken).decimals();//获取并存储抵押代币的小数
        priceFeed = AggregatorV3Interface(_priceFeed);//将合约连接到 Chainlink 价格源，使其能够按需获取实时价格数据

        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);//授予角色 让所有者完全控制合约的角色系统
        _grantRole(PRICE_FEED_MANAGER_ROLE, _initialOwner);//让所有者在将来需要时更新价格源
    }

    function getCurrentPrice() public view returns (uint256) {//从 Chainlink 获取实时价格
        (, int256 price, , , ) = priceFeed.latestRoundData();//从 Chainlink 聚合器接口调用 latestRoundData()
        require(price > 0, "Invalid price feed response");//检查返回的价格大于零
        return uint256(price);
    }


    //铸造稳定币

    function mint(uint256 amount) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();//阻止用户铸造零稳定币

        uint256 collateralPrice = getCurrentPrice();//获取抵押代币的当前实时价格
        uint256 requiredCollateralValueUSD = amount * (10 ** decimals()); // 假设 sUSD 为 18 位小数
        //用户想要铸造的稳定币的 USD 价值
        uint256 requiredCollateral = (requiredCollateralValueUSD * collateralizationRatio) / (100 * collateralPrice);
        //计算用户需要存入多少抵押品价值（以 USD 计
        uint256 adjustedRequiredCollateral = (requiredCollateral * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());
        //调整数字以确保计算对于抵押代币和价格源都是精度正确的
        collateralToken.safeTransferFrom(msg.sender, address(this), adjustedRequiredCollateral);//将所需数量的抵押品从用户转入合约
        _mint(msg.sender, amount);//铸造请求数量的 sUSD 稳定币

        emit Minted(msg.sender, amount, adjustedRequiredCollateral);//触发 Minted 事件
    }

    // 赎回稳定币

    function redeem(uint256 amount) external nonReentrant {
        if (amount == 0) revert MintAmountIsZero();//止零值赎回
        if (balanceOf(msg.sender) < amount) revert InsufficientStablecoinBalance();//试图销毁比他们持有的更多，交易被回滚

        uint256 collateralPrice = getCurrentPrice();//取抵押代币的最新真实世界价格
        uint256 stablecoinValueUSD = amount * (10 ** decimals());
        uint256 collateralToReturn = (stablecoinValueUSD * 100) / (collateralizationRatio * collateralPrice);
        //计算应该返回多少抵押品价值
        uint256 adjustedCollateralToReturn = (collateralToReturn * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        _burn(msg.sender, amount);//销毁正在赎回的稳定币
        collateralToken.safeTransfer(msg.sender, adjustedCollateralToReturn);//一旦 sUSD 被销毁，计算的抵押品数量安全地发送回用户的钱包

        emit Redeemed(msg.sender, amount, adjustedCollateralToReturn);//发出一个 Redeemed 事
    }

    function setCollateralizationRatio(uint256 newRatio) external onlyOwner {//更新抵押率
        if (newRatio < 100) revert CollateralizationRatioTooLow();
        collateralizationRatio = newRatio;
        emit CollateralizationRatioUpdated(newRatio);
    }

    function setPriceFeedContract(address _newPriceFeed) external onlyRole(PRICE_FEED_MANAGER_ROLE) {//更新价格源
        if (_newPriceFeed == address(0)) revert InvalidPriceFeedAddress();
        priceFeed = AggregatorV3Interface(_newPriceFeed);
        emit PriceFeedUpdated(_newPriceFeed);
    }

    function getRequiredCollateralForMint(uint256 amount) public view returns (uint256) {//预览所需抵押品
        if (amount == 0) return 0;

        uint256 collateralPrice = getCurrentPrice();
        uint256 requiredCollateralValueUSD = amount * (10 ** decimals());
        uint256 requiredCollateral = (requiredCollateralValueUSD * collateralizationRatio) / (100 * collateralPrice);
        uint256 adjustedRequiredCollateral = (requiredCollateral * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        return adjustedRequiredCollateral;
    }

    function getCollateralForRedeem(uint256 amount) public view returns (uint256) {//预览赎回时返回的抵押品
        if (amount == 0) return 0;

        uint256 collateralPrice = getCurrentPrice();
        uint256 stablecoinValueUSD = amount * (10 ** decimals());
        uint256 collateralToReturn = (stablecoinValueUSD * 100) / (collateralizationRatio * collateralPrice);
        uint256 adjustedCollateralToReturn = (collateralToReturn * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        return adjustedCollateralToReturn;
    }

}

