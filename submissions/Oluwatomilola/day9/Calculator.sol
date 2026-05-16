// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    import "./ScientificCalculator.sol";

contract Calculator {constructor() {
        owner = msg.sender;
    }


    modifier onlyOwner () {
        require(msg.sender == owner, "Only owner can perform");
        _;
    }


    function power(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) return 1;
        else return (base ** exponent);
    }

    function squareRoot(uint256 number) public pure returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        if (number == 0) return 0;

        int256 public result = number / 2;
        for (uint256 i = 0; i < 10; i++) {
            result = (result + number / result) / 2;
        }
        return result;
    }

    function setScientificCalculator(address _address) public onlyOwner{
        scientificCalculatorAddress = _address;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a + b;
        return result;
    }

    function subtraction(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a - b;
        return result;
    }

    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a * b;
        return result;
    }

    function division(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        uint256 result = a / b;
        return result;
    }

     function calculatePower(uint256 base, uint256 exponient) public view returns {
        ScientificCalculator scientificCalc = ScientificCalculator(ScientificCalculatorAddress);
        uint256 result = ScientificCalc.power(base, exponient);
        return result;
    }

    function calculateSquareRoot(uint256 number) public returns(uint256) {
        require(number >= 0,"Cannot calculate squareroot of negative number");
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        (bool success, bytes memory returnData) = ScientificCalculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }
    
}