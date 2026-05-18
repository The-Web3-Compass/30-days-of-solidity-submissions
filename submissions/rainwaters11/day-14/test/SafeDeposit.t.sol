// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../VaultManager.sol";
import "../VaultImplementations.sol";

contract SafeDepositTest is Test {
    VaultManager internal manager;

    function setUp() public {
        manager = new VaultManager();
    }

    function testTheLock() public {
        address boxAddress = manager.deployTimeLockedDepositBox(1 days);
        TimeLockedDepositBox box = TimeLockedDepositBox(boxAddress);

        string memory secret = "treasure-map";

        // VaultManager deploys boxes, so it is the box owner in this implementation.
        vm.prank(address(manager));
        box.storeSecret(secret);

        vm.expectRevert(bytes("Box is still time-locked"));
        vm.prank(address(manager));
        box.getSecret();
    }

    function testTheUnlock() public {
        address boxAddress = manager.deployTimeLockedDepositBox(1 days);
        TimeLockedDepositBox box = TimeLockedDepositBox(boxAddress);

        string memory secret = "treasure-map";

        vm.prank(address(manager));
        box.storeSecret(secret);

        vm.warp(block.timestamp + 1 days + 1 seconds);

        vm.prank(address(manager));
        string memory unlockedSecret = box.getSecret();

        assertEq(unlockedSecret, secret);
    }
}
