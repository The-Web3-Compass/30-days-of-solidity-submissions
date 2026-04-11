// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Calculator.sol";

contract Caller {
    Calculator public calc;

    constructor(address _calcAddress) {
        calc = Calculator(_calcAddress);
    }

    function callAdd(uint a, uint b) public view returns(uint) {
        return calc.add(a, b);
    }

    function callSub(uint a, uint b) public view returns(uint) {
        return calc.sub(a, b);
    }

    function callMul(uint a, uint b) public returns(uint) {
        (bool success, bytes memory data) = address(calc).call(
            abi.encodeWithSignature("mul(uint256,uint256)", a, b)
        );

        require(success, "Low-level call failed");

        return abi.decode(data, (uint));
    }

    function callDiv(uint a, uint b) public returns(uint) {
        (bool success, bytes memory data) = address(calc).call(
            abi.encodeWithSignature("div(uint256,uint256)", a, b)
        );

        require(success, "Low-level call failed");

        return abi.decode(data, (uint));
    }
}