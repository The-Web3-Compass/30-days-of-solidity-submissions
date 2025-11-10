// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SimpleTradingBot.sol";

contract MockERC20 is IERC20 {
    string public name = "Mock";
    string public symbol = "MCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount);
        require(allowance[from][msg.sender] >= amount);
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract MockRouter is IExchangeRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256, address[] calldata path, address to, uint256) external returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(msg.sender, to, amountIn);
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn;
    }
}

contract SimpleTradingBotTest is Test {
    SimpleTradingBot bot;
    MockRouter router;
    MockERC20 tokenA;
    MockERC20 tokenB;

    function setUp() public {
        router = new MockRouter();
        bot = new SimpleTradingBot(address(router));
        tokenA = new MockERC20();
        tokenB = new MockERC20();
        tokenA.balanceOf[address(this)] = 1_000e18;
    }

    function testCreateAndExecuteStrategy() public {
        tokenA.approve(address(bot), 500e18);
        bot.deposit(address(tokenA), 500e18);
        uint256 id = bot.createStrategy(address(tokenA), address(tokenB), 100e18, 1500, 500, address(0));
        tokenA.approve(address(router), 100e18);
        bot.executeStrategy(id, 0);
    }
}
