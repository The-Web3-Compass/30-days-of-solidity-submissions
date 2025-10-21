//SPDX-License-Identifer:MIT

pragma solidity ^0.8.18;

contract Counter {

    uint256 public counter;

    function increase(uint256 _input) public returns (uint256){

        return counter += _input;
    }

    function decrease(uint256 _input) public returns(uint256){
        unchecked{
        return counter -= _input;
        }
    }
}