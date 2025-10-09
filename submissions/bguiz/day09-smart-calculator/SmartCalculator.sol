// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import "./ICalc.sol";

/**
 * @title SmartCalculator
 * @dev Build a contract that uses another contract to do calculations.
 * You'll learn how contracts can talk to each other by calling functions of other contracts (using `address casting`).
 * It's like having one app ask another app to do some math, showing how to interact with other contracts.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 9
 */
contract SmartCalculator {
    address public manager;
    ICalc public calculatorImpl;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager is allowed to perform this action");
        _;
    }

    function updateImplementation(ICalc newImpl) public onlyManager {
        require(address(newImpl) != address(0x00), "calculator implementation cannot be null address");
        // TODO EIP-165 require
        calculatorImpl = newImpl;
    }

    function calculate(string memory method, uint256[] memory numbers) public view returns(uint256) {
        require(address(calculatorImpl) != address(0x00), "no calculator implementation set");
        return calculatorImpl.calculate(method, numbers);
    }
}
