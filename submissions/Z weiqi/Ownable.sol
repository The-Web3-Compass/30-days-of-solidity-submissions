//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable{
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);//emit广播了该条信息，并记录下（）里的内容，从没有所有者address到新的msg.sender

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");//==代表比较运算，在比较到底是不是这个人
        _;
    }

    function ownerAddress() public view returns (address) {
        return owner;//owner是私有的，但是public都可以查看是谁的，相当于“企查查”
    }

    function transferOwnership(address _newOwner) public onlyOwner{
        require (_newOwner !=address(0), "Invalid address");
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous, _newOwner);

    }


}