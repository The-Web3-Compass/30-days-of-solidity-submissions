// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract SimpleStorage{

    uint256 number;
    function store(uint256 num) public{
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }

} 