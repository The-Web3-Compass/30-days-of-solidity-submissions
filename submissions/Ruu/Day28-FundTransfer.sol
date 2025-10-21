//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract FundTransfer{
    address public owner;
    uint256 public received;

    constructor(){
        owner = msg.sender;
    }

    function receiveEther() external payable{
        received += msg.value;
    }

    function withdrawEther() external{
        require(msg.sender == owner, "Only owner can call this function");
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() external view returns(uint256){
        return address(this).balance;
    }
}
