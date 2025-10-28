// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "./Scientific.sol";
contract caculate{

    address public owner;
    address public scientificAddress;

    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
         _; 
    }

    function scientificCaculate(address _address) public onlyOwner {
        scientificAddress = _address;
    }

    function add(uint256 a, uint256 b) public pure returns(uint256) {
        uint256 result = a+b;
        return result;
    }
    function subtract(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a-b;
        return result;
    }

    function multiply(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a*b;
        return result;
    }
    function divide(uint256 a, uint256 b)public pure returns(uint256){
        require(b!= 0, "Cannot divide by zero");
        uint256 result = a/b;
        return result;
    }
    function cPower(uint256 base, uint256 ex) public view returns(uint256) {
        Scientific _presult = Scientific(scientificAddress);

        uint256 result = _presult.power(base, ex);

        return result;
    }

    function cSquare(uint256 number) public returns(uint256) {
        require(number >=0,"must be positive number.");

        bytes memory data = abi.encodeWithSignature("square(uint256)",number);
        (bool success, bytes memory re)=scientificAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(re, (uint256));
        return result;
    }

}