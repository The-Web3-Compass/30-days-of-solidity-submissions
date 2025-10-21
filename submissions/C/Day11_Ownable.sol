// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner; // 跟踪当前所有者

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (){
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    // 限制对敏感功能的访问
    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can");
        _;
    }

    function ownerAddress() public view returns(address){
        return owner;
    }
    // 允许转让所有权
    function transferOwnership(address _newOwner)public onlyOwner{
        require(_newOwner != address(0),"Invalid address");
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous, _newOwner); //发出事件，以便公开记录所有权更改
    }
}