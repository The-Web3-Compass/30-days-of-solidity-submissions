// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pollstation{
    string[] public candidateNames;
    mapping(string => uint256) public voteCount;
    mapping(string => bool) public isCandidate;

    function addCandidateNames(string memory _candidateNames) public{
        candidateNames.push(_candidateNames);
        isCandidate[_candidateNames] = true;
        voteCount[_candidateNames] = 0;
    }
    function getcandidateNames() public view returns(string[] memory){
        return candidateNames;
    }
    function vote(string memory _candidateNames) public {
        require(isCandidate[_candidateNames], "Candidate does not exist");
        voteCount[_candidateNames] += 1;
        
    }
    function getvote(string memory _candidateNames) public view returns(uint256) {
        return voteCount[_candidateNames];
    }

}