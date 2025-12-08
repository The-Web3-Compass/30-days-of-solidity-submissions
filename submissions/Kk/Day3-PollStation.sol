// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    //store candidates and their votes
    string[] public candidateNames;//array
    mapping(string => uint256) public voteCount;//mapping

    //initialize info of candidates, and the vote count to 0 at the begining.
    function addCandidateNames(string memory _candidateNames) public {
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }

    //retrieve list of candidates
    function getcandidateNames() public view returns (string[] memory){
        return candidateNames;
    }

    //vote function
    function vote(string memory _candidateNames) public {
        voteCount[_candidateNames] +=1;
    }

    //retrieve vote count
    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }

}
