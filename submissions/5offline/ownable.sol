// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//弄懂一半
contract Ownable {
    //一种母合约和子合约，子合约可以直接遵循改规则
    //感觉是前几天的合集，可以在piggybank中使用

    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function ownerAddress() public view returns (address) {
        return owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous, _newOwner);
    }
}