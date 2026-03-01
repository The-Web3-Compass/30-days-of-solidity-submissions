
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{
    string[] candidateNames;
    address public owner;
    uint256 votingStart;
    uint256 votingEnd;
    mapping(string => uint256) public voteCount; 
    mapping (address => bool) hasVoted;
    mapping (string => bool) isCandidate;

    event Voted(address indexed voter, string candidate, uint256 timestamp);
    
    
    constructor(uint256 _durationInDays){
        owner = msg.sender;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + (_durationInDays * 1 days);
    }
    modifier onlyOwner(){
        require(msg.sender == owner,"This action can only do by Owner");
        _;
    }


    function addCandidates(string memory _candidateName)public onlyOwner{
        candidateNames.push(_candidateName);
        isCandidate[_candidateName] = true;
        voteCount[_candidateName] = 0;
    }
    function getCandidateNames() public view returns(string[] memory){
        return candidateNames;
    }
    function vote(string memory _candidateName) public {
        require(block.timestamp >= votingStart,"Voting not started.");
        require(block.timestamp <= votingEnd,"Voting ended.");
        require(isCandidate[_candidateName],"Invalid candidate");
        require(!hasVoted[msg.sender],"Alredy voted");
       voteCount[_candidateName] +=1;
       hasVoted[msg.sender] = true;
       emit Voted(msg.sender, _candidateName, block.timestamp);
    }
    function getVote(string memory _candidateName) public view returns(uint256){
        require(isCandidate[_candidateName],"Invalid candidate");
        return voteCount[_candidateName];
    }
    function getWinner() public view returns(string memory winner,uint256 winningVotes){
        require(block.timestamp > votingEnd,"Voting still active");
        winningVotes = 0;
        uint256 length = candidateNames.length;
        for(uint256 i =0; i < length;i++){
            uint256 votes =voteCount[candidateNames[i]];
            if(votes > winningVotes){
                winner = candidateNames[i];
            }
        }
        return (winner, winningVotes);
    }
}