//SPDX-License-Identifer: MIT

pragma solidity ^0.8.18;

contract TipJar{

    struct Creator{
        string creatorName;
        uint256 balanceOf;
        bool isRegistered;
    }

    mapping(address => Creator) public creatorMap;


    function registerUser(string memory _name) public {
        require(creatorMap[msg.sender].isRegistered == false, "Already registered");
        creatorMap[msg.sender] = Creator(_name, 0, true);
    }   

    function deposit(address _creatorAddress) public payable {
        require(creatorMap[_creatorAddress].isRegistered == true, "Not registered");
        creatorMap[_creatorAddress].balanceOf += msg.value;
    }


    function getbalance(address _creatorAddress) public view returns(uint256, string memory){
        return (creatorMap[_creatorAddress].balanceOf, creatorMap[_creatorAddress].creatorName);
    }
}