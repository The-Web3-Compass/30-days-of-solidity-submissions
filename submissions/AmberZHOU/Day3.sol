//SPDX-License-Identifier: MIT

pragma solidity^0.8.0;

contract PollStation{
    string[] public candidatesName;
    mapping (string =>uint256) voteCount;
    
    function addCandidatesName(string memory _candidatesNames) public{
        candidatesName.push(_candidatesNames);
        voteCount[_candidatesNames]=0;  //store the vote in mapping array for that candidate names and initial value is 0
    }

    function vote (string memory _candidatesName) public{
        voteCount[_candidatesName]+= 1;
    }

    function getCandidatesNames() public view returns(string[]memory ){
        return candidatesName;
    }

    function getVote (string memory _candidatesName) public view returns (uint256){
        return voteCount[_candidatesName];
    }

}