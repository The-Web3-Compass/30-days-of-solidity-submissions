// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import "./ICalc.sol";

/**
 * @title CalcV2
 * @dev a first (not very good) implem entation of ICalc for SmartCalculator
 */
contract CalcV2 is ICalc {
    function areStringsEqual(string memory a, string memory b) public pure returns(bool) {
        return (
            bytes(a).length == bytes(b).length &&
            keccak256(bytes(a)) == keccak256(bytes(b))
        );
    }

    function calculate(string memory method, uint256[] memory numbers) external pure returns(uint256) {
        if (areStringsEqual(method, "add")) {
            require(numbers.length == 2, "add only allows 2 parameters");
            return numbers[0] + numbers[1];
        }
        if (areStringsEqual(method, "subtract")) {
            require(numbers.length == 2, "subtract only allows 2 parameters");
            require(numbers[0] >= numbers[1], "subtract for these numbers will underflow");
            return numbers[0] - numbers[1];
        }
        if (areStringsEqual(method, "multiply")) {
            require(numbers.length == 2, "multiply only allows 2 parameters");
            return numbers[0] * numbers[1];
        }
        if (areStringsEqual(method, "divide")) {
            require(numbers.length == 2, "divide only allows 2 parameters");
            require(numbers[1] > 0, "divide does not allow zero divisor");
            return numbers[0] / numbers[1];
        }
        require(false, "unsupported method");
    }
}
