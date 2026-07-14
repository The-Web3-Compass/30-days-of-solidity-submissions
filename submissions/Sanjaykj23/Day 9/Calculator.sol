// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ScientificCalculator.sol";
contract calculator{
    address scientificAddr;
    address owner;
    scientificCalculator scfiCal;
    constructor(){
        owner=msg.sender;
    }
    modifier onlyowner(){
        require(msg.sender==owner,"Not an Owner!");
        _;
    }
    function setSicientificAddress(address addr)onlyowner public {
        scientificAddr=addr;
        scfiCal=scientificCalculator(scientificAddr);

    }
    function getMod(uint a,uint b)public returns(uint){
        require(scientificAddr!=address(0));
        uint ans=scfiCal.remainder(a,b);
        return ans;
    }
        function add(uint256 a, uint256 b)public pure returns(uint256){
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
}