// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/InjectiveClobDemo.sol";

contract InjectiveClobDemoTest is Test {
    InjectiveClobDemo demo;

    function setUp() public {
        demo = new InjectiveClobDemo();
    }

    function testDeploy() public {
        assertTrue(address(demo) != address(0));
    }

    
    function testPlaceRevertsOnLocal() public {
        vm.expectRevert(); // no precompile on local
        demo.place(address(0x1234), true, 1e6, 1e18);
    }
}
