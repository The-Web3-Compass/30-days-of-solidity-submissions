// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TipJar{
    address public owner;
    uint256 public totalEarned;
    address public higherTipper;
    mapping(address => uint256) public tippers;

    constructor(){
        owner = msg.sender;
    }
    function tip() public payable{
       require(msg.value >0 , "invalid amount");
       totalEarned += msg.value;
       tippers[msg.sender] += msg.value;
       if(tippers[msg.sender] > tippers[higherTipper]){
        higherTipper = msg.sender;
       }
       
    }

    function withdrawTip() public {
        uint256 balance = address(this).balance;
        require(msg.sender == owner , "it is not for you!");
        require(totalEarned > balance , "insufficient balance");
        totalEarned -= balance;
        (bool success ,) = owner.call{value:balance}("");
        require(success , "withdrawal failed");

    }
}