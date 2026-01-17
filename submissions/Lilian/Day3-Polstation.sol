// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidatNames;
    mapping(string=>uint256)voteCount;

    function addCandidateNmes(string memory memorycandidiateNames)public {
        candidatNames.push(candidatNames);
        voteCount[candidatNames]=0;
    }
    function getcandidatNames()public view returns (string[] memory){
        return candidatNames
    }
    function vote(string memorycandidiateNames) public {
        VoteCount[candidatNames]+=1;
    }

    function getvote(string memorycandidiateNames)public view returns (uint256){
        return voteCount [candidatNames];
    }
}