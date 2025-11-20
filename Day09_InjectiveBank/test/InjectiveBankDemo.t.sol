// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/InjectiveBankDemo.sol";

contract InjectiveBankDemoTest is Test {
    function testDeployment() public {
        InjectiveBankDemo demo = new InjectiveBankDemo();
        assert(address(demo) != address(0));
    }
}
