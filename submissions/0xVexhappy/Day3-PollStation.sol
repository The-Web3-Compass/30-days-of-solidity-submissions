// SPDX-License-Identifier: MIT
// @author 0xVexhappy

pragma solidity ^0.8.31;

contract PollStation{
    address public admin;
    mapping(string => uint256) voteCount;
    string[] public candidateNames;
    mapping(address => bool) public hasVoted;
    mapping(string => bool) public isCandidate;
    uint256 public votingStart;
    uint256 public votingEnd;
    mapping(address => string) public voterChoice;
    event Voted(address indexed voter, string candidate, uint256 timestamp);

    constructor(uint256 _durationInDays){
        admin = msg.sender;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + (_durationInDays * 1 days);
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, 'Only Admin Can Add Candidate!');
        _;
    }

    function addCandidateNames(string memory _candidateNames) public onlyAdmin {
        candidateNames.push(_candidateNames);
        isCandidate[_candidateNames] = true;
        voteCount[_candidateNames] = 0;
    }

    function getCandidateNames() public view returns(string[] memory){
        return candidateNames;
    }

    function vote(string memory _candidateNames) public {
        require(block.timestamp >= votingStart, 'Voting not started!');
        require(block.timestamp <= votingEnd, 'Voting ended!');
        require(isCandidate[_candidateNames], 'Invalid Candidate');
        require(!hasVoted[msg.sender], 'Has Voted Already');
        voterChoice[msg.sender] = _candidateNames;
        hasVoted[msg.sender] = true;
        voteCount[_candidateNames] += 1;

        emit Voted(msg.sender, _candidateNames, block.timestamp);
    }

    function getVote(string memory _candidateNames) public view returns(uint256){
        return voteCount[_candidateNames];
    }

    function getWinner() public view returns(string memory winner, uint256 winningVoteCount){
        require(block.timestamp > votingEnd, 'Voting still active!');
        
        winningVoteCount = 0;
        uint256 length = candidateNames.length;
        for (uint i = 0; i < length; i++){
            uint256 votes = voteCount[candidateNames[i]];
            if (votes > winningVoteCount){
                winningVoteCount = votes;
                winner = candidateNames[i];
            }
        }
    }
}
