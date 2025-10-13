// SPDX-License-identifier:MIT
pragma solidity ^0.8.0;
cintract pollstation{
    string[] public candidates;
    mapping(string=>uint256) public voteCount;
    function addCandidate(string memory _candidates) public{
        candidates.push(_candidates);
    voteCount[_candidates]=0;
    }
    function vote(string memory _candidates) public{
        voteCount[_candidates]++;
    }
    function getCandidates() public view returns(string[] memory){
        return candidates;
    }
    function getVoteCount(string memory _candidates) public view returns(uint256){
        return voteCount[_candidates];
    }
}
