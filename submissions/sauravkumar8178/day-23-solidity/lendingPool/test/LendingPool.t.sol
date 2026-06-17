// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ERC20Mock.sol";
import "../src/InterestRateModel.sol";
import "../src/LendingPool.sol";
import "../src/IPriceOracle.sol";

contract OracleMock is IPriceOracle {
    mapping(address => uint256) public prices;
    function setPrice(address token, uint256 price) external { prices[token] = price; }
    function getPrice(address token) external view override returns (uint256) { return prices[token]; }
}

contract LendingPoolTest is Test {
    ERC20Mock tokenA; // borrowable asset (e.g., stable token)
    ERC20Mock tokenB; // collateral asset (e.g., wrapped token)
    InterestRateModel rateModel;
    OracleMock oracle;
    LendingPool pool;

    address alice = address(0xA1);
    address bob = address(0xB1);
    address liquidator = address(0xL1);

    function setUp() public {
        tokenA = new ERC20Mock("TokenA", "TKA");
        tokenB = new ERC20Mock("TokenB", "TKB");
        rateModel = new InterestRateModel(1e15, 2e15); // small rates per block
        oracle = new OracleMock();
        pool = new LendingPool(IPriceOracle(address(oracle)), rateModel);

        // list assets
        pool.listAsset(address(tokenA));
        pool.listAsset(address(tokenB));

        // mint tokens
        tokenA.mint(address(this), 1e24);
        tokenB.mint(address(this), 1e24);
        tokenA.mint(bob, 1e21);
        tokenB.mint(bob, 1e21); // bob will deposit collateral
        tokenA.mint(liquidator, 1e21);

        // set prices: tokenA = $1, tokenB = $2 (1e18)
        oracle.setPrice(address(tokenA), 1e18);
        oracle.setPrice(address(tokenB), 2e18);

        // supply liquidity: this test contract supplies tokenA liquidity to pool
        tokenA.approve(address(pool), type(uint256).max);
        pool.supply(address(tokenA), 1e24 / 1000); // supply some liquidity
    }

    function testBorrowAndLiquidation() public {
        // Bob deposits collateral tokenB
        vm.startPrank(bob);
        tokenB.approve(address(pool), 1e21);
        pool.depositCollateral(address(tokenB), 1e21 / 1000);
        vm.stopPrank();

        // Bob borrows 1 tokenA
        vm.startPrank(bob);
        pool.borrow(address(tokenA), 1e18); // borrow 1 * 1e18
        vm.stopPrank();

        // lower collateral price to make bob undercollateralized
        oracle.setPrice(address(tokenB), 5e17); // tokenB price halved

        // Liquidator performs liquidation
        vm.startPrank(liquidator);
        tokenA.approve(address(pool), 1e21);
        // ensure liquidator has tokenA (we minted earlier)
        pool.liquidate(address(tokenA), bob, 1e18, address(tokenB));
        vm.stopPrank();

        // check liquidator received some tokenB seized collateral
        uint256 seized = tokenB.balanceOf(liquidator);
        assertGt(seized, 0);
    }
}
