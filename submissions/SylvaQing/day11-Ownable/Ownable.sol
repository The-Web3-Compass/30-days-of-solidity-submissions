// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Ownable{
    address private owner;

    //注册转换地址事件
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(){
        owner =msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner!=address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner,_newOwner);
        owner = _newOwner;
    }
}