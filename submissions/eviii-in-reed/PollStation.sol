//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract pollStation{
    string[] public candidateNames;
    mapping(string => uint256) voteCount;

    function addCandidates(string memory _candidateName) public {
        candidateNames.push(_candidateName);
        voteCount[_candidateName] = 0;
    }

    function vote(string memory _candidateName) public {
        voteCount[_candidateName] ++;
    }

    function getCandidatesNames() public view returns (string[] memory){
        return candidateNames; //**view** means just getting a value not changing anything
    }

    function getVote(string memory _candidateName) public view returns (uint256){
        return voteCount[_candidateName];
    }
}
