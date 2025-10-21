//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] candidates;
    mapping(string => uint256) voteCount;

    function addCandidates(string memory _Candidate) public {
        candidates.push(_Candidate);             
        voteCount[_Candidate] =0;
    }

    function vote(string memory _Candidate) public{
        voteCount[_Candidate]++;
    }

    function getCandidates() public view returns(string[] memory){
        return candidates;
    }

    function getVote(string memory _Candidate) public view returns(uint256){
        return voteCount[_Candidate];
    }

}
