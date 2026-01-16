// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public canNames;
    mapping(string => uint256) voteC;

    function addCanNames(string memory _canNames) public{
        canNames.push(_canNames);
        voteC[_canNames] = 0;
    }
    
    function getcanNames() public view returns (string[] memory){
        return canNames;
    }

    function vote(string memory _canNames) public{
        voteC[_canNames] += 1;
    }

    function getVote(string memory _canNames) public view returns (uint256){
        return voteC[_canNames];
    }

}
