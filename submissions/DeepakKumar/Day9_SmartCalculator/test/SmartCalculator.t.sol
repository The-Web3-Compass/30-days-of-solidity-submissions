// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Calculator.sol";
import "../src/SmartCalculator.sol";

contract SmartCalculatorTest is Test {
    Calculator calc;
    SmartCalculator smartCalc;

    function setUp() public {
        calc = new Calculator();
        smartCalc = new SmartCalculator(address(calc));
    }

    function testAddition() public {
        uint256 result = smartCalc.addNumbers(10, 20);
        assertEq(result, 30);
    }

    function testSubtraction() public {
        uint256 result = smartCalc.subtractNumbers(50, 20);
        assertEq(result, 30);
    }

    function testMultiplication() public {
        uint256 result = smartCalc.multiplyNumbers(5, 6);
        assertEq(result, 30);
    }

    function testDivision() public {
        uint256 result = smartCalc.divideNumbers(60, 2);
        assertEq(result, 30);
    }
}
