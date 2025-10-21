//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

contract Ownable{
    address private owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (){
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can perform this action.");
        _;
    }
    //查看所有者
    function ownerAddress() public view returns(address){
        return(owner);
    }

    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0), "invalid address");
        address _previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(_previousOwner, _newOwner);
    }
}