// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract LendingPool {
    using SafeERC20 for IERC20;
    
    address public immutable daiToken;
    address public immutable usdcToken;
    address public immutable wethToken;
    address public immutable daiEthPriceFeed;
    address public immutable usdcEthPriceFeed;
    uint256 public constant SUPPLY_RATE = 3;
    uint256 public constant BORROW_RATE = 5;
    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant LIQUIDATION_THRESHOLD = 125;
    uint256 public constant LIQUIDATION_BONUS = 5;
    
    struct UserData {
        uint256 depositedDai;
        uint256 depositedUsdc;
        uint256 depositedEth;
        uint256 borrowedDai;
        uint256 borrowedUsdc;
        uint256 borrowedEth;
        uint256 lastUpdated;
    }
    
    mapping(address => UserData) public users;
    
    event Deposit(address indexed user, address token, uint256 amount);
    event Withdraw(address indexed user, address token, uint256 amount);
    event Borrow(address indexed user, address token, uint256 amount);
    event Repay(address indexed user, address token, uint256 amount);
    event Liquidate(
        address indexed liquidator,
        address indexed borrower,
        address token,
        uint256 amount,
        uint256 collateralSeized
    );
    
    constructor(
        address _daiToken,
        address _usdcToken,
        address _wethToken,
        address _daiEthPriceFeed,
        address _usdcEthPriceFeed
    ) {
        daiToken = _daiToken;
        usdcToken = _usdcToken;
        wethToken = _wethToken;
        daiEthPriceFeed = _daiEthPriceFeed;
        usdcEthPriceFeed = _usdcEthPriceFeed;
    }
    
    function deposit(address token, uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than 0");
        updateInterest(msg.sender);
        
        if (token == wethToken) {
            require(msg.value == amount, "ETH value mismatch");
            users[msg.sender].depositedEth += amount;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            if (token == daiToken) {
                users[msg.sender].depositedDai += amount;
            } else if (token == usdcToken) {
                users[msg.sender].depositedUsdc += amount;
            } else {
                revert("Unsupported token");
            }
        }
        
        emit Deposit(msg.sender, token, amount);
    }
    
    function withdraw(address token, uint256 amount) external {
        updateInterest(msg.sender);
        UserData storage user = users[msg.sender];
        
        if (token == wethToken) {
            require(user.depositedEth >= amount, "Insufficient balance");
            user.depositedEth -= amount;
            payable(msg.sender).transfer(amount);
        } else if (token == daiToken) {
            require(user.depositedDai >= amount, "Insufficient balance");
            user.depositedDai -= amount;
            IERC20(daiToken).safeTransfer(msg.sender, amount);
        } else if (token == usdcToken) {
            require(user.depositedUsdc >= amount, "Insufficient balance");
            user.depositedUsdc -= amount;
            IERC20(usdcToken).safeTransfer(msg.sender, amount);
        } else {
            revert("Unsupported token");
        }
        
        require(
            getCollateralizationRatio(msg.sender) >= COLLATERAL_RATIO,
            "Withdrawal would make you undercollateralized"
        );
        
        emit Withdraw(msg.sender, token, amount);
    }
    
    function borrow(address token, uint256 amount) external {
        updateInterest(msg.sender);
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 collateralValue = getCollateralValue(msg.sender);
        uint256 borrowValue = getBorrowValue(msg.sender);
        uint256 tokenPrice = getTokenPrice(token);
        uint256 newBorrowValue = borrowValue + (amount * tokenPrice) / 1e18;
        
        require(
            (collateralValue * 100) / newBorrowValue >= COLLATERAL_RATIO,
            "Insufficient collateral"
        );
        
        if (token == wethToken) {
            users[msg.sender].borrowedEth += amount;
            payable(msg.sender).transfer(amount);
        } else if (token == daiToken) {
            users[msg.sender].borrowedDai += amount;
            IERC20(daiToken).safeTransfer(msg.sender, amount);
        } else if (token == usdcToken) {
            users[msg.sender].borrowedUsdc += amount;
            IERC20(usdcToken).safeTransfer(msg.sender, amount);
        } else {
            revert("Unsupported token");
        }
        
        emit Borrow(msg.sender, token, amount);
    }
    
    function repay(address token, uint256 amount) external payable {
        updateInterest(msg.sender);
        UserData storage user = users[msg.sender];
        
        if (token == wethToken) {
            require(msg.value == amount, "ETH value mismatch");
            require(user.borrowedEth >= amount, "Repaying more than borrowed");
            user.borrowedEth -= amount;
        } else {
            if (token == daiToken) {
                require(user.borrowedDai >= amount, "Repaying more than borrowed");
                user.borrowedDai -= amount;
                IERC20(daiToken).safeTransferFrom(msg.sender, address(this), amount);
            } else if (token == usdcToken) {
                require(user.borrowedUsdc >= amount, "Repaying more than borrowed");
                user.borrowedUsdc -= amount;
                IERC20(usdcToken).safeTransferFrom(msg.sender, address(this), amount);
            } else {
                revert("Unsupported token");
            }
        }
        
        emit Repay(msg.sender, token, amount);
    }
    
    function liquidate(address borrower, address token) external payable {
        updateInterest(borrower);
        
        require(
            getCollateralizationRatio(borrower) < LIQUIDATION_THRESHOLD,
            "Borrower is not liquidatable"
        );
        
        UserData storage user = users[borrower];
        uint256 debtToCover;
        
        if (token == wethToken) {
            require(msg.value > 0, "ETH value must be greater than 0");
            debtToCover = msg.value;
            require(debtToCover <= user.borrowedEth, "Repaying more than borrowed");
            user.borrowedEth -= debtToCover;
        } else {
            if (token == daiToken) {
                debtToCover = IERC20(daiToken).balanceOf(msg.sender);
                require(debtToCover > 0, "Amount must be greater than 0");
                require(debtToCover <= user.borrowedDai, "Repaying more than borrowed");
                user.borrowedDai -= debtToCover;
                IERC20(daiToken).safeTransferFrom(msg.sender, address(this), debtToCover);
            } else if (token == usdcToken) {
                debtToCover = IERC20(usdcToken).balanceOf(msg.sender);
                require(debtToCover > 0, "Amount must be greater than 0");
                require(debtToCover <= user.borrowedUsdc, "Repaying more than borrowed");
                user.borrowedUsdc -= debtToCover;
                IERC20(usdcToken).safeTransferFrom(msg.sender, address(this), debtToCover);
            } else {
                revert("Unsupported token");
            }
        }
        
        uint256 tokenPrice = getTokenPrice(token);
        uint256 collateralValue = (debtToCover * tokenPrice * (100 + LIQUIDATION_BONUS)) / (100 * 1e18);
        uint256 collateralToSeize = collateralValue / getEthPrice();
        
        require(
            collateralToSeize <= user.depositedEth,
            "Seizing more than available collateral"
        );
        
        user.depositedEth -= collateralToSeize;
        
        payable(msg.sender).transfer(collateralToSeize);
        
        emit Liquidate(msg.sender, borrower, token, debtToCover, collateralToSeize);
    }
    
    function updateInterest(address user) public {
        UserData storage data = users[user];
        uint256 timeElapsed = block.timestamp - data.lastUpdated;
        
        if (timeElapsed > 0) {

            data.depositedDai += (data.depositedDai * SUPPLY_RATE * timeElapsed) / (365 days * 100);
            data.depositedUsdc += (data.depositedUsdc * SUPPLY_RATE * timeElapsed) / (365 days * 100);
            data.depositedEth += (data.depositedEth * SUPPLY_RATE * timeElapsed) / (365 days * 100);
            data.borrowedDai += (data.borrowedDai * BORROW_RATE * timeElapsed) / (365 days * 100);
            data.borrowedUsdc += (data.borrowedUsdc * BORROW_RATE * timeElapsed) / (365 days * 100);
            data.borrowedEth += (data.borrowedEth * BORROW_RATE * timeElapsed) / (365 days * 100);
        }
        
        data.lastUpdated = block.timestamp;
    }
    
    function getTokenPrice(address token) public view returns (uint256) {
        if (token == wethToken) {
            return 1e18; // 1 ETH = 1 ETH
        } else if (token == daiToken) {
            (, int price, , , ) = AggregatorV3Interface(daiEthPriceFeed).latestRoundData();
            return uint256(price) * 1e10; // Convert to 18 decimals
        } else if (token == usdcToken) {
            (, int price, , , ) = AggregatorV3Interface(usdcEthPriceFeed).latestRoundData();
            return uint256(price) * 1e10; // Convert to 18 decimals
        }
        revert("Unsupported token");
    }
    
    function getEthPrice() public pure returns (uint256) {
        return 1e18; 
    }
    
    function getCollateralValue(address user) public view returns (uint256) {
        UserData memory data = users[user];
        return data.depositedEth;
    }
    
    function getBorrowValue(address user) public view returns (uint256) {
        UserData memory data = users[user];
        uint256 daiValue = (data.borrowedDai * getTokenPrice(daiToken)) / 1e18;
        uint256 usdcValue = (data.borrowedUsdc * getTokenPrice(usdcToken)) / 1e18;
        uint256 ethValue = data.borrowedEth;
        return daiValue + usdcValue + ethValue;
    }
    
    function getCollateralizationRatio(address user) public view returns (uint256) {
        uint256 collateralValue = getCollateralValue(user);
        uint256 borrowValue = getBorrowValue(user);
        
        if (borrowValue == 0) {
            return type(uint256).max;
        }
        
        return (collateralValue * 100) / borrowValue;
    }
    
    function getAvailableCollateral(address user) public view returns (uint256) {
        uint256 collateralValue = getCollateralValue(user);
        uint256 borrowValue = getBorrowValue(user);
        uint256 requiredCollateral = (borrowValue * COLLATERAL_RATIO) / 100;
        
        if (requiredCollateral >= collateralValue) {
            return 0;
        }
        
        return collateralValue - requiredCollateral;
    }
    
    function getBorrowLimit(address user) public view returns (uint256) {
        uint256 collateralValue = getCollateralValue(user);
        return (collateralValue * 100) / COLLATERAL_RATIO;
    }
    
    function getBorrowUtilization(address user) public view returns (uint256) {
        uint256 borrowValue = getBorrowValue(user);
        uint256 borrowLimit = getBorrowLimit(user);
        
        if (borrowLimit == 0) {
            return 0;
        }
        
        return (borrowValue * 100) / borrowLimit;
    }
    
    receive() external payable {}
}
