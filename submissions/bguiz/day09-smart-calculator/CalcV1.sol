// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import "./ICalc.sol";

/**
 * @title CalcV1
 * @dev a first (not very good) implem entation of ICalc for SmartCalculator
 */
contract CalcV1 is ICalc {
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
            return numbers[0] - numbers[1];
        }
        require(false, "unsupported method");
    }
}
