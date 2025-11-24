// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MathLibrary} from "./MathLibrary.sol"; // using as library

interface IMathLibrary { // using the contract
    function add(uint256 a, uint256 b) external pure returns(uint256);
    function sub(uint256 a, uint256 b)external pure returns(uint256);
    function div(uint256 a, uint256 b) external pure returns(uint256);
    function mul(uint256 a, uint256 b) external pure returns(uint256);
    function power(uint256 a, uint256 b) external pure returns(uint256);

}

contract SmartCalculator {
    error SmartCalculator_InvalidOperation();
    error SmartCalculator_UnAuthorized();

    bytes32 private constant ADD_HASH = keccak256(bytes("add"));
    bytes32 private constant POWER_HASH = keccak256(bytes("power"));
    bytes32 private constant MUL_HASH = keccak256(bytes("mul"));
    bytes32 private constant SUB_HASH = keccak256(bytes("sub"));
    bytes32 private constant DIV_HASH = keccak256(bytes("div"));

    using MathLibrary for uint256;
    IMathLibrary public mathContract;
    address public owner;

    event CalculationPerformed(string indexed operation, uint a, uint b, uint result);
    event MathContractUpdated(address indexed oldContract, address indexed newContract);
  
    constructor(address _mathContract) {
        owner = msg.sender;
        mathContract = IMathLibrary(_mathContract);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert SmartCalculator_UnAuthorized();
        _;
    }

    function updateMathContract(address _mathContract) external onlyOwner {
        require(_mathContract != address(0));
        address oldContract = address(mathContract);
        mathContract = IMathLibrary(_mathContract);
        emit MathContractUpdated(oldContract, _mathContract);
    }

    function calculatePowerLib(uint256 a, uint256 b) public pure returns (uint256) {
       return a.power(b);
    }

    function calculatePowerContract(uint256 a, uint256 b) external view returns (uint256) {
        return mathContract.power(a,b);
    }

    function addNumber(uint256 a, uint256 b) public pure returns (uint256){
        return a.add(b);
    }

    function addNumberContract(uint256 a, uint256 b) public view returns (uint256){
        return mathContract.add(a,b);
    }

    function performCalculation (
        string memory operation,
        uint a,
        uint b
    ) public returns (uint) {
        uint result;
        bytes32 op = keccak256(bytes(operation));

        if (op == ADD_HASH) {
            result = mathContract.add(a,b);
        } else if (op == POWER_HASH) {
            result = mathContract.power(a,b);
        } else if (op == SUB_HASH) {
            result = mathContract.sub(a,b);
        } else if (op == MUL_HASH) {
            result = mathContract.mul(a,b);
        } else if (op == DIV_HASH) {
            result = mathContract.div(a,b);
        } else {
            revert SmartCalculator_InvalidOperation();
        }

        emit CalculationPerformed(operation, a, b, result);
        return result;

    }

    function getOwner() public view returns(address) {
        return owner;
    }
    
}