//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{

    string [] public CandidateNames;
    mapping (string => uint256)public voteCount;

    function addAndvoteCandidates(string memory _CandidateNames) public {
        CandidateNames.push(_CandidateNames);
        voteCount[(_CandidateNames)] =0;
    }
    
    function vote(string memory _CandidateNames) public {
        voteCount[_CandidateNames] += 1;
    }
    

}