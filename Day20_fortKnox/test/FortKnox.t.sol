// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/GoldVault.sol";
import "../src/GoldThief.sol";

contract FortKnoxTest is Test {
    GoldVault vault;
    GoldThief thief;

    address attacker = address(0xBEEF);
    address user = address(0xCAFE);

    function setUp() public {
        vault = new GoldVault();
        vm.deal(attacker, 10 ether);
        vm.deal(user, 5 ether);

        // legitimate user deposits 5 ETH into vault
        vm.startPrank(user);
        vault.deposit{value: 5 ether}();
        vm.stopPrank();
    }

    function testVulnerableAttack() public {
        vm.startPrank(attacker);
        thief = new GoldThief(address(vault));
        thief.attackVulnerable{value: 1 ether}();
        vm.stopPrank();

        console.log("Vault balance after attack:", address(vault).balance);
        console.log("Thief balance after attack:", thief.getBalance());

        // Attacker should have gained >1 ether
        assertGt(thief.getBalance(), 1 ether, "Attack should drain more than 1 ETH");
    }

    function testSafeWithdrawPreventsAttack() public {
    GoldVault safeVault = new GoldVault();

    // Legit user deposits 5 ETH
    vm.startPrank(user);
    safeVault.deposit{value: 5 ether}();
    vm.stopPrank();

    vm.startPrank(attacker);
    GoldThief safeThief = new GoldThief(address(safeVault));

    // Expect revert, because reentrancy should be blocked
    vm.expectRevert(); 
    safeThief.attackSafe{value: 1 ether}();
    vm.stopPrank();

    console.log("Safe vault balance after attack:", address(safeVault).balance);
    console.log("Safe thief balance after attack:", safeThief.getBalance());

    // Even after revert, vault should still have 5 ETH
    assertEq(address(safeVault).balance, 5 ether, "Vault should remain safe");
    }
}
