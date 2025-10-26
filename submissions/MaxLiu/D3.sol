// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidates;
    mapping(string => uint256) voteCount;

    function addCandidateNames(string memory _candidates) public{
        candidates.push(_candidates);
        voteCount[_candidates] = 0;
    }
    
    function getcandidateNames() public view returns (string[] memory){
        return candidates;
    }

    function vote(string memory _candidates) public{
        voteCount[_candidates] += 1;
    }

    function getVote(string memory _candidates) public view returns (uint256){
        return voteCount[_candidates];
    }

}