//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract PollStation {
    string[] public CandidateNames; //public - everyone can access, the array of candidate names,keep it dynamic
    mapping(string => uint256)  public VoteCount ; //to track votes //what if i want to map one item to multiple items?
    /* CandidateNames and VoteCount are the names of the variables
       in the end, the main goal is to know how many votes each candidate has received */

    //add new candidates
    function addCandidateNames(string memory _CandidateNames)public {
        CandidateNames.push(_CandidateNames); // add the new item to the array, we are passing in a string memory
        VoteCount[_CandidateNames] =0; // set the initial number of vote = 0
    }

    //how the vote works
    function vote(string memory _CandidateNames)public {
        VoteCount[_CandidateNames]++;
    }

    //to track candidate names
    function getCandidateNames() public view returns(string[] memory){
        return CandidateNames;
    }
    
    //to get how many votes the candidate have
    function getVote(string memory _CandidateNames)public view returns(uint256){
        return VoteCount[_CandidateNames];
    }

}