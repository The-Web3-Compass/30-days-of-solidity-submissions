// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SmartCalculator.sol";
contract Calculator{
    address public owner;
    address public ScCalcAddress;

    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can do this actiosm");
        _;
    }
    function setScientificCalc(address _address) public onlyOwner{
        ScientificCalcAdd = _address;   
    }

    function add(uint256 a , uint256 b) public pure returns(uint256){
        uint256 res = a+b;
        return res;
    }

    function subs(uint256 a , uint256 b) public pure returns(uint256){
        uint256 res = a-b;
        return res;
    }

    function multiply(256 a , uint256 b) public pure returns(uint256){
        uint256 res = a*b;
        return res;
    }

    function divide(256 a , uint256 b) public pure returns(uint256){
        require(b! = 0 , "Cannot divide by zero");
        uint256 res = a/b;
        return res;
    }

    function expo(uint256 base, uint256 exp) public view returns(uint256){
        ScientificCalculator scAddress = ScientificCalculator(scAddress);
        // external call
        uint256 res = scAddress.power(base,exponent);
        return res;
    }

    function sqRoot(uint256 num) public returns(uint256){
        require(num >= 0 , "Can't calculate sq root of negative number");
        bytes memory data = abi.encodeWithSignature("sqRoot(int256)",num);
        (bool success, bytes memory returnData) = scAddress.call(data);
        require(success,"External call failed");
        uint256 res = abi.decode(returnData,(uint256));
        return res;
    }
}