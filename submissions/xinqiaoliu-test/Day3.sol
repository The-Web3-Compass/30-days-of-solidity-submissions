// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation {
    string []  public CandidateNames;
    mapping(string => uint256) VoteCount;

    function addCandidateNames(string memory _candidateNames) public {
        CandidateNames. push(_candidateNames);
        VoteCount[_candidateNames] = 0;
    }

    function  vote(string memory _candidateNames) public {
        VoteCount[_candidateNames] ++;
}
    function getcandidateNames() public view returns (string[] memory) {
    return CandidateNames;
}

    function getVote(string memory _candidateNames) public view returns (uint256) {
    return VoteCount[_candidateNames];
}

}