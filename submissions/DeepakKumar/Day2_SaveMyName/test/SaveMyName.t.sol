// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/SaveMyName.sol";

contract SaveMyNameTest is Test {
    SaveMyName saveMyName;

    function setUp() public {
        saveMyName = new SaveMyName();
    }

    function testSaveAndGetProfile() public {
        saveMyName.saveMyProfile("Alice", "I build dApps");
        (string memory name, string memory bio) = saveMyName.getMyProfile();
        assertEq(name, "Alice");
        assertEq(bio, "I build dApps");
    }
}
