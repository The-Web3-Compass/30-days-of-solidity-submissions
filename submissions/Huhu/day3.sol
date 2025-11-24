// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[]public candidateNames;
    mapping(string =>uint256) public voteCount;
    mapping(address => bool) public hasVoted; //防止重复投票
    mapping(string => bool)  public isCandidate; //检查候选人是否存在

    function addCandidateNames(string memory _candidateNames) public{
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
        isCandidate[_candidateNames] = true;

    }

    function getCandidateNames( )public view returns (string[]memory){
        return candidateNames;
    }

    function vote(string memory _candidateNames) public{
        require(!hasVoted[msg.sender], unicode"你已经投过票!");
        require(isCandidate[_candidateNames], unicode"候选人不存在！");
        voteCount[_candidateNames] += 1; 
        hasVoted[msg.sender] = true ;

    }

    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];
    }
}
