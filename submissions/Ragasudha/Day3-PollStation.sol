// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    address public admin;
    string[] public candidateNames;
    mapping(string => uint256) public voteCount;
    mapping(address => bool) public hasVoted;
    mapping(string => bool) public isCandidate;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function addCandidateNames(string memory _candidateNames) public onlyAdmin {
        candidateNames.push(_candidateNames);
        isCandidate[_candidateNames] = true;
        voteCount[_candidateNames] = 0;
    }

    function vote(string memory _candidateNames) public {
        require(isCandidate[_candidateNames], "Invalid candidate");
        require(!hasVoted[msg.sender], "Already voted");
        
        hasVoted[msg.sender] = true;
        voteCount[_candidateNames] += 1;
    }

    function getcandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function getVote(string memory _candidateNames) public view returns (uint256) {
        return voteCount[_candidateNames];
    }
}