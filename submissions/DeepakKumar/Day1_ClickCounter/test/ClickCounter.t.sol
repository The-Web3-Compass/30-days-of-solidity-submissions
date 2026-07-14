// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ClickCounter.sol";

contract ClickCounterTest is Test {
    ClickCounter counter;

    function setUp() public {
        counter = new ClickCounter();
    }

    function testIncrement() public {
        counter.click();
        assertEq(counter.getCount(), 1);
    }

    function testDecrement() public {
        counter.click();
        counter.unclick();
        assertEq(counter.getCount(), 0);
    }

    function testReset() public {
        counter.click();
        counter.reset();
        assertEq(counter.getCount(), 0);
    }
}
