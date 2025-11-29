// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    mapping(string => uint256)voteCount;

    function addNames(string memory names)public{
        candidateNames.push(names);
        voteCount[names] = 0;
    }
    function getNames()public view returns (string[]memory){
        return candidateNames;

    }
    function vote(string memory names)public{
        voteCount[names] +=1;
    }
    function getVote(string memory names)public view returns(uint256){
        return voteCount[names];
    }
}
