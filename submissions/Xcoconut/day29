// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// --- 模拟合约 (用于测试) ---

contract CollateralToken is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH") {
        _mint(msg.sender, 100 * 10**18);
    }
}

contract MockPriceFeed {
    int256 private price;
    uint8 private constant DECIMALS = 8;

    constructor(int256 _initialPrice) {
        price = _initialPrice;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (1, price, block.timestamp, block.timestamp, 1);
    }
    
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }
}

// --- 核心合约 ---

contract Stablecoin is ERC20, Ownable {
    constructor() ERC20("My Stablecoin", "MSC") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}

contract Engine is Ownable {
    // --- 状态变量 ---
    Stablecoin public immutable stablecoin;
    IERC20 public immutable collateralToken;
    MockPriceFeed public immutable priceFeed;

    uint256 public constant LIQUIDATION_THRESHOLD = 50; // 50%
    uint256 public constant LIQUIDATION_BONUS = 10; // 10%
    uint256 public constant COLLATERAL_RATIO = 150; // 150%

    mapping(address => uint256) public collateralDeposited;
    mapping(address => uint256) public stablecoinMinted;

    // --- 事件 ---
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralRedeemed(address indexed user, uint256 amount);
    event StablecoinMinted(address indexed user, uint256 amount);
    event StablecoinBurned(address indexed user, uint256 amount);

    constructor(
        address _stablecoinAddress,
        address _collateralTokenAddress,
        address _priceFeedAddress
    ) Ownable(msg.sender) {
        stablecoin = Stablecoin(_stablecoinAddress);
        collateralToken = IERC20(_collateralTokenAddress);
        priceFeed = MockPriceFeed(_priceFeedAddress);
    }

    // --- 核心功能 ---

    function depositCollateral(uint256 _amount) external {
        collateralDeposited[msg.sender] += _amount;
        collateralToken.transferFrom(msg.sender, address(this), _amount);
        emit CollateralDeposited(msg.sender, _amount);
    }

    function mintStablecoin(uint256 _amount) external {
        uint256 collateralValue = getAccountCollateralValue(msg.sender);
        uint256 maxStablecoinToMint = (collateralValue * 100) / COLLATERAL_RATIO;
        
        require(_amount > 0, "Amount must be positive");
        require(stablecoinMinted[msg.sender] + _amount <= maxStablecoinToMint, "Exceeds max mintable amount");

        stablecoinMinted[msg.sender] += _amount;
        stablecoin.mint(msg.sender, _amount);
        emit StablecoinMinted(msg.sender, _amount);
    }

    function burnStablecoin(uint256 _amount) external {
        require(_amount > 0, "Amount must be positive");
        require(stablecoinMinted[msg.sender] >= _amount, "Not enough minted stablecoins");

        stablecoinMinted[msg.sender] -= _amount;
        stablecoin.burn(msg.sender, _amount);
        emit StablecoinBurned(msg.sender, _amount);
    }

    function redeemCollateral(uint256 _amount) external {
        require(_amount > 0, "Amount must be positive");
        require(collateralDeposited[msg.sender] >= _amount, "Not enough collateral");

        uint256 newCollateralValue = (collateralDeposited[msg.sender] - _amount) * getCollateralPrice() / 1e8;
        uint256 totalDebtValue = stablecoinMinted[msg.sender]; // Simplified: 1 stablecoin = $1
        
        require(newCollateralValue * 100 / COLLATERAL_RATIO >= totalDebtValue, "Redemption would make position unsafe");

        collateralDeposited[msg.sender] -= _amount;
        collateralToken.transfer(msg.sender, _amount);
        emit CollateralRedeemed(msg.sender, _amount);
    }

    function liquidate(address _user) external {
        uint256 collateralValue = getAccountCollateralValue(_user);
        uint256 totalDebtValue = stablecoinMinted[_user];
        uint256 liquidationThresholdValue = (collateralValue * LIQUIDATION_THRESHOLD) / 100;

        require(totalDebtValue > liquidationThresholdValue, "Position is not eligible for liquidation");
        
        uint256 collateralToLiquidate = (totalDebtValue * 1e8) / getCollateralPrice();
        uint256 bonusCollateral = (collateralToLiquidate * LIQUIDATION_BONUS) / 100;
        uint256 totalCollateralToSeize = collateralToLiquidate + bonusCollateral;

        stablecoin.transferFrom(msg.sender, address(this), totalDebtValue);
        collateralToken.transfer(msg.sender, totalCollateralToSeize);

        collateralDeposited[_user] -= totalCollateralToSeize;
        stablecoinMinted[_user] = 0;
        stablecoin.burn(address(this), totalDebtValue);
    }

    // --- 视图函数 ---

    function getCollateralPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getAccountCollateralValue(address _user) public view returns (uint256) {
        uint256 collateralAmount = collateralDeposited[_user];
        return (collateralAmount * getCollateralPrice()) / 1e8;
    }
}
