// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SmartCalculator {
    function power(uint _base, uint _exponent) public pure returns(uint){
       if(_exponent == 0) return 0;
       return (_base ** _exponent);
    }

    function squareRoot(int _number) public pure returns(int){
        if(_number == 0) return 0;
        int result = _number/2;
        for(uint i = 0; i<10; i++){
            result = (result + _number/result)/2;
        }
        return result;
    }
}

contract Calculator {
    address public owner;
    address public smartCalculatorAddress;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "not allowed");
        _;
    }

    function smartCalculator(address _address) public onlyOwner(){
        smartCalculatorAddress = _address;
    }

    function add(uint _a, uint _b) public  pure returns(uint){
        return _a + _b;
    }

    function subtract(uint _a, uint _b) public pure returns(int){
        return int(_a-_b);
    }

    function multiply(uint _a, uint _b) public pure returns(uint){
        return _a*_b;
    }

    function divide(uint _a, uint _b) public pure returns(uint){
        require(_b != 0, "cant divide by 0");

        return _a/_b;
    }

    function calculatePower(uint _base, uint _exponent) public view returns(uint){
        SmartCalculator smartCalc = SmartCalculator(smartCalculatorAddress);

        return smartCalc.power(_base, _exponent);
    }

    function calculateSquareRoot(int _number) public returns(uint){
        require(_number > 0, "cant calculate square root of a negative number");

        bytes memory data = abi.encodeWithSignature("squareRoot(int)", _number);
        (bool success, bytes memory returnData) = smartCalculatorAddress.call(data);

        require(success, "external call failed");
        uint result = uint(abi.decode(returnData, (int)));
        return result;
    }
}