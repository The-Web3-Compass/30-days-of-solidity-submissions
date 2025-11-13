//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Ownable{

    address private owner;
    event TransferOwner(address preOwner,string notice,address newOwner);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"only owner can call this function");
        _;
    } 

    function getOwnerAdr() public view returns(address){
        return owner;
    }

    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0),"Invalid address!");
        address previous = owner;
        owner =  newOwner;
        emit TransferOwner(previous,"Ownership Transfered",owner);
    }

}