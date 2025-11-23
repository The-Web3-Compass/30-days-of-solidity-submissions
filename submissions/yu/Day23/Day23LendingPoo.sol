// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * (10**decimals()));
    }
}

/**
 * @title MockPriceFeed
 * @dev 模拟一个Chainlink价格预言机。
 */
contract MockPriceFeed is Ownable {
    int256 private price; // 价格，带8位小数
    uint8 private constant DECIMALS = 8;

    constructor(int256 _initialPrice) Ownable(msg.sender) {
        price = _initialPrice;
    }

    function setPrice(int256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (1, price, block.timestamp, block.timestamp, 1);
    }
    
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }
}

// --- 核心借贷池合约 ---

/**
 * @title LendingPool
 * @dev 一个基础的去中心化借贷池。
 */
contract LendingPool is Ownable {
    // --- 状态变量 ---
    IERC20 public immutable asset; // 可借贷的资产 (如 DAI)
    IERC20 public immutable collateralToken; // 抵押品资产 (如 WETH)
    
    MockPriceFeed public immutable assetPriceFeed;
    MockPriceFeed public immutable collateralPriceFeed;

    // 用户存款 (作为贷方)
    mapping(address => uint256) public assetDeposits;
    // 用户抵押品存款
    mapping(address => uint256) public collateralDeposits;
    // 用户借款 (债务)
    mapping(address => uint256) public userBorrows;

    // 借贷利率 (例如，5% 表示为 5)
    uint256 public borrowRatePerYear = 5;

    // 贷款价值比 (Loan-To-Value)，例如 75%
    uint256 public constant LTV_RATIO = 75;

    // --- 事件 ---
    event Deposited(address indexed user, uint256 amount, bool isCollateral);
    event Withdrawn(address indexed user, uint256 amount, bool isCollateral);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

    constructor(
        address _assetAddress,
        address _collateralTokenAddress,
        address _assetPriceFeedAddress,
        address _collateralPriceFeedAddress
    ) Ownable(msg.sender) {
        asset = IERC20(_assetAddress);
        collateralToken = IERC20(_collateralTokenAddress);
        assetPriceFeed = MockPriceFeed(_assetPriceFeedAddress);
        collateralPriceFeed = MockPriceFeed(_collateralPriceFeedAddress);
    }

    // --- 存款与取款 ---

    function deposit(uint256 _amount, bool _isCollateral) external {
        require(_amount > 0, "Amount must be > 0");
        if (_isCollateral) {
            collateralDeposits[msg.sender] += _amount;
            collateralToken.transferFrom(msg.sender, address(this), _amount);
        } else {
            assetDeposits[msg.sender] += _amount;
            asset.transferFrom(msg.sender, address(this), _amount);
        }
        emit Deposited(msg.sender, _amount, _isCollateral);
    }

    function withdraw(uint256 _amount, bool _isCollateral) external {
        if (_isCollateral) {
            require(collateralDeposits[msg.sender] >= _amount, "Insufficient collateral deposit");
            // 在提取抵押品前，检查是否会导致资不抵债
            uint256 newCollateralValue = (collateralDeposits[msg.sender] - _amount) * getCollateralPrice() / 1e8;
            uint256 debtValue = userBorrows[msg.sender] * getAssetPrice() / 1e8;
            require(newCollateralValue * LTV_RATIO / 100 >= debtValue, "Withdrawal would make position unsafe");
            
            collateralDeposits[msg.sender] -= _amount;
            collateralToken.transfer(msg.sender, _amount);
        } else {
            require(assetDeposits[msg.sender] >= _amount, "Insufficient asset deposit");
            assetDeposits[msg.sender] -= _amount;
            asset.transfer(msg.sender, _amount);
        }
        emit Withdrawn(msg.sender, _amount, _isCollateral);
    }

    // --- 借款与还款 ---

    function borrow(uint256 _amount) external {
        require(_amount > 0, "Amount must be > 0");
        require(collateralDeposits[msg.sender] > 0, "No collateral deposited");

        uint256 collateralValue = collateralDeposits[msg.sender] * getCollateralPrice() / 1e8;
        uint256 maxBorrowableValue = collateralValue * LTV_RATIO / 100;

        uint256 currentDebtValue = userBorrows[msg.sender] * getAssetPrice() / 1e8;
        uint256 newDebtValue = (_amount * getAssetPrice() / 1e8) + currentDebtValue;

        require(newDebtValue <= maxBorrowableValue, "Borrow amount exceeds borrowing power");

        userBorrows[msg.sender] += _amount;
        asset.transfer(msg.sender, _amount);
        emit Borrowed(msg.sender, _amount);
    }

    function repay(uint256 _amount) external {
        require(_amount > 0, "Amount must be > 0");
        require(userBorrows[msg.sender] >= _amount, "Repay amount exceeds debt");

        // 在一个简化的模型中，我们暂时不计算利息。
        // 在真实世界中，这里会有一个复杂的利息计算。
        userBorrows[msg.sender] -= _amount;
        asset.transferFrom(msg.sender, address(this), _amount);
        emit Repaid(msg.sender, _amount);
    }

    // --- 视图与辅助函数 ---

    function getAssetPrice() public view returns (uint256) {
        (, int256 price, , , ) = assetPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getCollateralPrice() public view returns (uint256) {
        (, int256 price, , , ) = collateralPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getBorrowingPower(address _user) public view returns (uint256) {
        uint256 collateralValue = collateralDeposits[_user] * getCollateralPrice() / 1e8;
        return collateralValue * LTV_RATIO / 100;
    }
}