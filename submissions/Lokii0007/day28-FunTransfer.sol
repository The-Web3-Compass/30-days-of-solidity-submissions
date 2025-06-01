// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract FunTransfer {
    address public owner;
    uint public balance;

    constructor(){
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "amount > 0");
        balance += msg.value;
    }

    function withdraw() external {
        require(msg.sender == owner, "not allowed");
        require(address(this).balance > 0, "0 balance");
        payable(owner).transfer(address(this).balance);
    }

    function getBalamce() external view returns(uint) {
        return address(this).balance;
    }
}