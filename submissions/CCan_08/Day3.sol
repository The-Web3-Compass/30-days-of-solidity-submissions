// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;

contract PullStation{
    string[] public CandidateNames;
    mapping ( string => uint256) voteCount;
function addCandidateNames(string memory _CandidateNames) public {
    CandidateNames.push(_CandidateNames);
    voteCount[_CandidateNames]=0;
}
function getCandidateNames() public view returns (string[] memory){
    return CandidateNames;
}
function vote(string memory _CandidateNames) public {
    voteCount[_CandidateNames] += 1;
}
function getVote(string memory _CandidateNames) public view returns (uint256){
    return voteCount[_CandidateNames];
}
}