 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ownable {
    // 定义一个私有主用户
    address private owner;
// 记录日志为切换主用户
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        // 记录日志
        emit OwnershipTransferred(address(0), msg.sender);
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

