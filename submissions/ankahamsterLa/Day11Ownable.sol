// SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Transfer the ownership.
contract Ownable{
    address private owner;
    event OwnershipTransffered(address indexed previousOwner,address indexed newOwner);

    constructor(){
        owner=msg.sender;
        emit OwnershipTransffered(address(0),msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }

    function ownerAddress() public view returns(address){
        return owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner!=address(0),"Invalid address");
        address previous=owner;
        owner=_newOwner;
        emit OwnershipTransffered(previous,_newOwner);
    }
}