// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/StableUSD.sol";
import "../src/OracleManager.sol";
import "../src/MockOracle.sol";
import "../src/CollateralPool.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory sym, address to, uint256 amount) ERC20(name, sym) {
        _mint(to, amount);
    }
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract StablecoinTest is Test {
    StableUSD stable;
    OracleManager oracleManager;
    MockOracle mockOracle;
    CollateralPool pool;
    ERC20Mock token;
    address user = address(0xBEEF);

    function setUp() public {
        stable = new StableUSD();
        oracleManager = new OracleManager();

        // price = 1800 USD with 8 decimals => 1800 * 1e8 = 1800_00000000
        int256 price = int256(1800 * 1e8);
        mockOracle = new MockOracle(price);

        token = new ERC20Mock("MockWETH", "mWETH", address(this), 0);
        // mint tokens to user
        token.mint(user, 1 ether);

        // register oracle for token
        oracleManager.setAggregator(address(token), address(mockOracle));

        pool = new CollateralPool(address(stable), address(oracleManager));

        // grant minter/burner roles to pool
        bytes32 MINTER = keccak256("MINTER_ROLE");
        bytes32 BURNER = keccak256("BURNER_ROLE");
        stable.grantRole(MINTER, address(pool));
        stable.grantRole(BURNER, address(pool));

        // allow collateral
        pool.setAllowedCollateral(address(token), true);

        // user approves pool
        vm.startPrank(user);
        token.approve(address(pool), 1 ether);
        vm.stopPrank();
    }

    function testMintWithCollateral() public {
        vm.startPrank(user);
        // user mints with 1 token (1 WETH). Price 1800 => collateralValueUSD18 = 1 * 1800 * 1e8 / 1e8 = 1800 (18-dec implied)
        // collateralizationRatio = 150 => maxMintUSD18 = 1800 * 100 / 150 = 1200 (18 decimals)
        pool.mintWithCollateral(address(token), 1 ether, 0);
        vm.stopPrank();

        uint256 bal = stable.balanceOf(user);
        assertEq(bal, 1200 ether);
    }

    function testRedeemToCollateral() public {
        vm.startPrank(user);
        pool.mintWithCollateral(address(token), 1 ether, 0);
        // redeem 100 sUSD -> expect collateral returned roughly = usd * 1e8 / price
        uint256 redeemAmount = 100 ether;
        pool.redeemToCollateral(address(token), redeemAmount, 0);
        vm.stopPrank();

        // user collateral balance should be reduced; sUSD burned
        uint256 sBal = stable.balanceOf(user);
        assertEq(sBal, 1100 ether); // 1200 - 100 = 1100
    }
}