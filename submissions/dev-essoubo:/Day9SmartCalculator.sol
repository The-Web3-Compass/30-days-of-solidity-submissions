// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicMath {
    function add(uint a, uint b) public pure returns (uint) {
        return a + b;
    }

    function subtract(uint a, uint b) public pure returns (uint) {
        return a - b;
    }

    function multiply(uint a, uint b) public pure returns (uint) {
        return a * b;
    }

    function divide(uint a, uint b) public pure returns (uint) {
        require(b != 0, "Division by zero");
        return a / b;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SmartCalculator {
    address public mathContract;

    constructor(address _mathAddress) {
        mathContract = _mathAddress;
    }

    function useAdd(uint a, uint b) public view returns (uint) {
        (bool success, bytes memory data) = mathContract.staticcall(
            abi.encodeWithSignature("add(uint256,uint256)", a, b)
        );
        require(success, "Call to add failed");
        return abi.decode(data, (uint));
    }

    function useSubtract(uint a, uint b) public view returns (uint) {
        (bool success, bytes memory data) = mathContract.staticcall(
            abi.encodeWithSignature("subtract(uint256,uint256)", a, b)
        );
        require(success, "Call to subtract failed");
        return abi.decode(data, (uint));
    }

    function useMultiply(uint a, uint b) public view returns (uint) {
        (bool success, bytes memory data) = mathContract.staticcall(
            abi.encodeWithSignature("multiply(uint256,uint256)", a, b)
        );
        require(success, "Call to multiply failed");
        return abi.decode(data, (uint));
    }

    function useDivide(uint a, uint b) public view returns (uint) {
        (bool success, bytes memory data) = mathContract.staticcall(
            abi.encodeWithSignature("divide(uint256,uint256)", a, b)
        );
        require(success, "Call to divide failed");
        return abi.decode(data, (uint));
    }
}
