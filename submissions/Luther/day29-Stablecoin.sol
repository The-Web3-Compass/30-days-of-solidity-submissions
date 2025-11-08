//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//引入 OpenZeppelin 提供的 ERC20 标准代币实现文件
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//引入 Ownable 合约模块，它定义了合约拥有者（owner）和 onlyOwner 权限控制机制
import "@openzeppelin/contracts/access/Ownable.sol";
//引入防止重入攻击的安全模块
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//引入 SafeERC20 工具库，用于安全地操作 ERC20 代币
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//引入基于角色的访问控制模块
//允许创建多种权限角色（例如“管理员”“喂价者”），比 Ownable 更灵活
import "@openzeppelin/contracts/access/AccessControl.sol";
//引入 ERC20 元数据接口，用于读取代币的名称（name）、符号（symbol）和小数位（decimals）
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
//引入 Chainlink 的价格预言机接口，用来读取链上喂价
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//定义了合约的主体；继承的父合约让它同时具备 ERC20 功能（代币）、Ownable 权限控制、防重入安全、角色控制
contract SimpleStablecoin is ERC20, Ownable, ReentrancyGuard, AccessControl {
    //声明使用 SafeERC20 工具库，用于安全地操作 ERC20 代币
    using SafeERC20 for IERC20;

    //定义一个角色常量 PRICE_FEED_MANAGER_ROLE，用来区分“喂价管理员”这个角色。
    bytes32 public constant PRICE_FEED_MANAGER_ROLE = keccak256("PRICE_FEED_MANAGER_ROLE");
    //定义一个角色常量 PRICE_FEED_MANAGER_ROLE，用来区分“喂价管理员”这个角色。
    IERC20 public immutable collateralToken;
    //保存抵押代币的小数位数（decimals）
    uint8 public immutable collateralDecimals;
    //定义一个 Chainlink 喂价接口变量，用于获取链上价格
    AggregatorV3Interface public priceFeed;
    //设置初始抵押率为 150%，也就是说，用户必须用价值 1.5 美元的抵押物，才能铸造 1 美元的稳定币
    uint256 public collateralizationRatio = 150; 

    //定义一个事件 Minted，在用户成功铸造稳定币时触发
    event Minted(address indexed user, uint256 amount, uint256 collateralDeposited);
    //定义 Redeemed 事件，在用户赎回（销毁）稳定币并取回抵押物时触发
    event Redeemed(address indexed user, uint256 amount, uint256 collateralReturned);
    //当管理员更新价格预言机合约地址时触发
    event PriceFeedUpdated(address newPriceFeed);
    //定义一个事件，用于记录抵押率变动
    event CollateralizationRatioUpdated(uint256 newRatio);

    //定义一个自定义错误，当抵押代币地址非法时触发
    //PsPs：相比 require() 的字符串提示，自定义错误更节省 gas
    error InvalidCollateralTokenAddress();
    //定义当喂价合约地址为 0 地址或非法时的错误类型
    error InvalidPriceFeedAddress();
    //当用户尝试铸造 0 数量的代币时触发此错误
    error MintAmountIsZero();
    //当用户尝试赎回超过自己持有的稳定币数量时触发
    error InsufficientStablecoinBalance();
    //当管理员试图将抵押率设置低于 100% 时触发此错误
    error CollateralizationRatioTooLow();

    //构造函数，在部署时执行一次，初始化代币信息与主要参数
    constructor(
        address _collateralToken,     //设置抵押代币地址
        address _initialOwner,     //设置喂价源
        address _priceFeed     //设定初始合约拥有者
    //用 ERC20 的构造函数设置代币名称和符号
    ) ERC20("Simple USD Stablecoin", "sUSD") Ownable(_initialOwner) {
        //检查抵押代币地址是否为零地址，如果是则抛出错误
        if (_collateralToken == address(0)) revert InvalidCollateralTokenAddress();
        //检查喂价合约地址是否有效
        if (_priceFeed == address(0)) revert InvalidPriceFeedAddress();

        //将抵押代币地址保存为 IERC20 接口实例
        //让合约能使用安全的 ERC20 接口函数与抵押物交互
        collateralToken = IERC20(_collateralToken);
        //从抵押代币合约中读取其小数位数（decimals()），并保存到本合约的 collateralDecimals 变量中
        collateralDecimals = IERC20Metadata(_collateralToken).decimals();
        //将 _priceFeed 地址转换为 AggregatorV3Interface 接口，并赋值给 priceFeed
        //这样合约就能通过这个接口与 Chainlink 喂价合约交互
        priceFeed = AggregatorV3Interface(_priceFeed);
        
        //为初始所有者分配管理员角色
        //授予部署者或指定地址完全的权限
        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        //给 _initialOwner 地址授予“喂价管理者角色”
        //允许该角色用户调用 setPriceFeedContract() 来更新价格预言机
        _grantRole(PRICE_FEED_MANAGER_ROLE, _initialOwner);
    }

    //定义一个公开的只读函数，用于获取抵押资产的实时价格
    function getCurrentPrice() public view returns (uint256) {
        //调用 Chainlink 的喂价接口 latestRoundData()，取出第二个返回值 price
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //检查从喂价返回的价格是否大于 0
        require(price > 0, "Invalid price feed response");
        //把价格从 int256 转换为 uint256 返回
        return uint256(price);
    }

    //声明一个外部可调用的函数 mint，带一个参数 amount（铸币数量），并使用 nonReentrant 修饰符防重入
    function mint(uint256 amount) external nonReentrant {
        //如果调用者传入的 amount 为 0，则立即回退并抛出自定义错误
        if (amount == 0) revert MintAmountIsZero();

        //调用 getCurrentPrice() 函数并把返回值存入 collateralPrice 变量
        uint256 collateralPrice = getCurrentPrice();
        //计算所需的抵押品价值（以 USD 为单位）
        //amount 乘以 10 的 decimals() 次方（假设 sUSD 有 18 位小数）
        //注意：这里 decimals() 是合约的 decimals() 函数，返回稳定币的小数位数
        uint256 requiredCollateralValueUSD = amount * (10 ** decimals()); 
        //计算所需的抵押品数量
        //requiredCollateralValueUSD 乘以 collateralizationRatio（抵押率，如 150 表示 150%）除以 100
        //再除以 collateralPrice（抵押资产的价格）得到所需的抵押资产数量
        uint256 requiredCollateral = (requiredCollateralValueUSD * collateralizationRatio) / (100 * collateralPrice);
        //把上一步计算得到的 requiredCollateral（在 price feed 的数值尺度下）转换为抵押代币的最小单位数量 (collateralDecimals)
        uint256 adjustedRequiredCollateral = (requiredCollateral * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        //使用 SafeERC20 的 safeTransferFrom 将 adjustedRequiredCollateral 数量的抵押代币从调用者账户转入本合约
        collateralToken.safeTransferFrom(msg.sender, address(this), adjustedRequiredCollateral);
        //调用 ERC20 的内部函数 _mint，在 msg.sender 账户上创建（铸造）amount 数量的 sUSD
        //将新生成的稳定币交付给用户，完成铸造流程
        _mint(msg.sender, amount);

        //触发 Minted 事件，记录谁铸了多少以及存入了多少抵押物
        emit Minted(msg.sender, amount, adjustedRequiredCollateral);
    }

    //声明外部可调用的 redeem 函数，用户可用它销毁 sUSD 并取回对应抵押物；同样受 nonReentrant 保护
    //允许用户赎回抵押资产：先销毁（burn）稳定币，然后把相应的抵押物返回用户
    function redeem(uint256 amount) external nonReentrant {
        //如果 amount 为 0，则回退并抛出 MintAmountIsZero() 错误
        if (amount == 0) revert MintAmountIsZero();
        //检查调用者持有的 sUSD 是否至少为 amount，若不足则回退并抛出 InsufficientStablecoinBalance()
        if (balanceOf(msg.sender) < amount) revert InsufficientStablecoinBalance();

        //再次获取当前抵押物价格并赋值给 collateralPrice
        uint256 collateralPrice = getCurrentPrice();
        //计算将要销毁的 amount sUSD 的美元价值
        uint256 stablecoinValueUSD = amount * (10 ** decimals());
        //基于要销毁的稳定币价值与当前抵押率、价格，计算应返还的抵押物在 price feed 单位下的数量
        uint256 collateralToReturn = (stablecoinValueUSD * 100) / (collateralizationRatio * collateralPrice);
        //将 collateralToReturn（在 price feed 尺度下）转换为抵押代币的最小单位数量，以便实际转账

        //将 collateralToReturn（在 price feed 尺度下）转换为抵押代币的最小单位数量，以便实际转账
        uint256 adjustedCollateralToReturn = (collateralToReturn * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());
        
        //销毁（burn）调用者账户上的 amount sUSD，从总供应中扣除
        _burn(msg.sender, amount);
        //把 adjustedCollateralToReturn 数量的抵押代币从合约发送给 msg.sender，使用 SafeERC20 的 safeTransfer
        collateralToken.safeTransfer(msg.sender, adjustedCollateralToReturn);

        //触发 Redeemed 事件，记录赎回行为：谁赎回了多少稳定币并拿回了多少抵押
        emit Redeemed(msg.sender, amount, adjustedCollateralToReturn);
    }

    //定义一个外部函数，owner（合约所有者）可以通过它更新抵押率
    //允许合约拥有者在必要时调整风险参数
    function setCollateralizationRatio(uint256 newRatio) external onlyOwner {
        //如果新比例小于 100（即低于 100%），回退并抛出错误
        if (newRatio < 100) revert CollateralizationRatioTooLow();
        //把新的抵押率写入状态变量 collateralizationRatio
        //更新系统参数，影响后续 mint/redeem 的计算
        collateralizationRatio = newRatio;
        //发出事件记录抵押率变更
        emit CollateralizationRatioUpdated(newRatio);
    }

    //定义一个函数，让被授予 PRICE_FEED_MANAGER_ROLE 的地址更新价格预言机合约地址
    //更细粒度权限控制：不是仅 owner，而是某个角色可以管理喂价合约，便于运维分工
    function setPriceFeedContract(address _newPriceFeed) external onlyRole(PRICE_FEED_MANAGER_ROLE) {
        //如果传入的地址为空地址则回退
        if (_newPriceFeed == address(0)) revert InvalidPriceFeedAddress();
        //把新地址转换为 AggregatorV3Interface 并保存在 priceFeed
        priceFeed = AggregatorV3Interface(_newPriceFeed);
        //触发事件记录价格合约变更
        emit PriceFeedUpdated(_newPriceFeed);
    }

    //公开只读函数，返回若要铸造 amount sUSD 需要的抵押代币数量（以抵押代币最小单位计）
    function getRequiredCollateralForMint(uint256 amount) public view returns (uint256) {
        //若请求的 amount 为 0，直接返回 0
        if (amount == 0) return 0;

        //读取当前价格
        uint256 collateralPrice = getCurrentPrice();
        //跟 mint 中相同，把 amount 扩展到 sUSD 的最小单位形成 USD 价值
        //用于计算需要多少抵押“价值”
        uint256 requiredCollateralValueUSD = amount * (10 ** decimals());
        //计算在 price feed 单位下需要多少抵押“价值”
        uint256 requiredCollateral = (requiredCollateralValueUSD * collateralizationRatio) / (100 * collateralPrice);
        //将上一步数值转换为抵押代币的最小单位
        //得到实际需要转账的 token 数量返回给调用方
        uint256 adjustedRequiredCollateral = (requiredCollateral * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        //返回计算得到的抵押代币数量（最小单位）
        return adjustedRequiredCollateral;
    }

    //公开只读函数，返回赎回 amount sUSD 时可以拿回多少抵押（以抵押代币最小单位计）
    function getCollateralForRedeem(uint256 amount) public view returns (uint256) {
        //若 amount 为 0，返回 0，避免多余计算
        if (amount == 0) return 0;

        //获取当前价格
        uint256 collateralPrice = getCurrentPrice();
        //把要赎回的 sUSD 扩展为最小单位下的 USD 价值（同样注意单位约定）
        uint256 stablecoinValueUSD = amount * (10 ** decimals());
        //计算以 price feed 单位表示应返还的抵押价值
        uint256 collateralToReturn = (stablecoinValueUSD * 100) / (collateralizationRatio * collateralPrice);
        //将其转换为抵押代币的最小单位，得出实际应转的 token 数量
        uint256 adjustedCollateralToReturn = (collateralToReturn * (10 ** collateralDecimals)) / (10 ** priceFeed.decimals());

        //返回计算结果（最小单位）
        return adjustedCollateralToReturn;
    }
    
}