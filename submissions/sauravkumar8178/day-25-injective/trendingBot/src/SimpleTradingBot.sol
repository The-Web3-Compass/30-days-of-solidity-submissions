// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IExchangeRouter.sol";
import "./interfaces/IPriceFeed.sol";

contract SimpleTradingBot is Ownable, ReentrancyGuard {
    struct Strategy {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint16 takeProfitPct;
        uint16 stopLossPct;
        address priceFeed;
        bool active;
    }

    IExchangeRouter public router;
    bool public paused;

    mapping(uint256 => Strategy) public strategies;
    uint256 public strategyCount;

    event StrategyCreated(uint256 indexed id, address indexed owner);
    event StrategyUpdated(uint256 indexed id);
    event StrategyExecuted(uint256 indexed id, uint256 amountIn, uint256[] amountsOut);
    event Deposited(address indexed who, address indexed token, uint256 amount);
    event Withdrawn(address indexed who, address indexed token, uint256 amount);
    event Paused(bool paused);

    modifier notPaused() {
        require(!paused, "paused");
        _;
    }

    constructor(address _router) {
        router = IExchangeRouter(_router);
    }

    function setRouter(address _router) external onlyOwner {
        router = IExchangeRouter(_router);
    }

    function createStrategy(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint16 takeProfitPct,
        uint16 stopLossPct,
        address priceFeed
    ) external onlyOwner returns (uint256) {
        require(tokenIn != address(0) && tokenOut != address(0), "invalid tokens");
        require(amountIn > 0, "amountIn>0");

        uint256 id = ++strategyCount;
        strategies[id] = Strategy({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            takeProfitPct: takeProfitPct,
            stopLossPct: stopLossPct,
            priceFeed: priceFeed,
            active: true
        });

        emit StrategyCreated(id, owner());
        return id;
    }

    function updateStrategy(uint256 id, uint256 amountIn, uint16 tp, uint16 sl) external onlyOwner {
        Strategy storage s = strategies[id];
        require(s.tokenIn != address(0), "no strategy");
        s.amountIn = amountIn;
        s.takeProfitPct = tp;
        s.stopLossPct = sl;
        emit StrategyUpdated(id);
    }

    function toggleStrategy(uint256 id, bool active) external onlyOwner {
        Strategy storage s = strategies[id];
        s.active = active;
        emit StrategyUpdated(id);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(true);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Paused(false);
    }

    function deposit(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "amount>0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, token, amount);
    }

    function emergencyWithdraw(address token, uint256 amount) external onlyOwner nonReentrant {
        IERC20(token).transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, token, amount);
    }

    function executeStrategy(uint256 id, uint256 minAcceptableOut) external notPaused nonReentrant {
        Strategy storage s = strategies[id];
        require(s.active, "inactive");
        _doSwap(s, minAcceptableOut);
    }

    function executeStrategyWithPrice(uint256 id, uint256, uint256 minAcceptableOut) external notPaused nonReentrant onlyOwner {
        Strategy storage s = strategies[id];
        require(s.active, "inactive");
        _doSwap(s, minAcceptableOut);
    }

    function _doSwap(Strategy storage s, uint256 minAcceptableOut) internal {
        IERC20(s.tokenIn).approve(address(router), 0);
        IERC20(s.tokenIn).approve(address(router), s.amountIn);

        address[] memory path = new address[](2);
        path[0] = s.tokenIn;
        path[1] = s.tokenOut;

        uint256 deadline = block.timestamp + 300;
        uint256[] memory amounts = router.swapExactTokensForTokens(s.amountIn, minAcceptableOut, path, address(this), deadline);

        emit StrategyExecuted(0, s.amountIn, amounts);
    }
}
