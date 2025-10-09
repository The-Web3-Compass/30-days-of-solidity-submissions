// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

interface ICalc {
    function calculate(string memory method, uint256[] memory numbers) external pure returns(uint256);
}
