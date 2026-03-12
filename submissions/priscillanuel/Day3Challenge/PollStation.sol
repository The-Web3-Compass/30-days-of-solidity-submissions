// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract PollStation{
    // lets declare the variables
    address public admin; // declares the admin
    uint256 public durationDays;// duration of the voting period
    bytes32[] public Candidates; // list of candidates in the poll
    mapping(address => bool) public voters; // tracks the voters
    mapping(address => bool) public hasVoted;// check if an address has voted
    mapping (bytes32 => bool) public isCandidate;// a verified candidate in the poll
    mapping(bytes32 => uint256) public voteCounts; //number of votes each candidate has received

    // declaring the contract deployer as admin and the Voting Duration
    constructor(uint256 _durationDays){
        admin = msg.sender;
        VotingStart = block.timestamp;
        VotingEnd = block.timestamp + (_durationDays * 2 days);
        
    }

  modifier onlyOwner() {
    require(msg.sender == admin, "You are not the admin");
    _; 
    }
    // function to add candidate name to the poll
    // and make sure only the admin can add a candidate
    function addCandidates(bytes32 _Candidates) public onlyOwner{
        Candidates.push(_Candidates);
        isCandidate[_Candidates] = true;
        voteCounts[_Candidates] = 0;
    }

    // function to know the names of candidates to ve voted for
    function CandidateNames() public view returns (bytes32[] memory) {
        return Candidates;
    }
    

    // ------------VOTING PERIOD--------------------

    uint256 public VotingStart; // the time the voting starts
    uint256 public VotingEnd; // the time the voting ends

    // function to vote for a candidate
    // and make sure an address can only vote once
    // set the voting period
    function vote(bytes32 _Candidates) public {
        require(block.timestamp >= VotingStart, "Voting has not started yet");
        require(block.timestamp <= VotingEnd, "Voting has ended");
        require (!hasVoted[msg.sender],"has already voted");
        hasVoted[msg.sender] = true;
        voteCounts[_Candidates] += 1;

    }

    //function to check a candidate vote
    function getVote(bytes32  _Candidates) public view returns (uint256) {
        return voteCounts[_Candidates];
    }

    //function to count each candidate votests
    function GetWinner()
     public view returns (bytes32 winner, uint256 WinnerVotesCounts ) {
        require (block.timestamp > VotingEnd, "Voting has not ended yet");

        WinnerVotesCounts = 0; 
        for (uint i = 0; i < Candidates.length; i++){
            uint256 votes = voteCounts[Candidates[i]];
            if (votes > WinnerVotesCounts) {
                WinnerVotesCounts = votes;
                winner = Candidates[i];
            }
        }




    }

   

    }