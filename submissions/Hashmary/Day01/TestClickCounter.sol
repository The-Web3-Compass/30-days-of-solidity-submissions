/*---------------------------------------------------------------------------
  File:   TestClickCounter.sol
  Author: Marion Bohr
  Date:   04/01/2025
  Description:
    Automatic test
  Usage:  forge test
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "Test/TestClickCounter.sol";
import "ClickCounter.sol";

contract TestClickCounter is Test {
    ClickCounter public counter;

    function setUp() public {
        counter = new ClickCounter();
    }

    function testInitialCount() public {
        assertEq(counter.getCount(), 0);
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.getCount(), 1);
    }

    function testDecrementRevert() public {
        vm.expectRevert("UnderflowError");
        counter.decrement();
    }

    function testOverflow() public {
        // Set _count to type(uint256).max
        vm.store(address(counter), bytes32(0), bytes32(type(uint256).max));
        vm.expectRevert("OverflowError");
        counter.increment();
    }
}