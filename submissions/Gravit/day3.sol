//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract pollingContract{
    string[]  candidateNames;
    mapping(string => uint256) voteCounts;

    function addCandidates(string memory _name) public {
       candidateNames.push(_name);
       voteCounts[_name] = 0;
    }

    function voteCandidate(string memory _name) public{
        voteCounts[_name] += 1;
    }
    
    function getVotes(string memory _name) public view returns (uint256){
        return voteCounts[_name];
    }

    function getAllCandidates() public view returns(string[] memory){
        return candidateNames;
    }

}