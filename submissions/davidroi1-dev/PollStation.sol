// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateName;
    mapping(string => uint256) public voteCount;
    mapping(address => string) public voter;

    function setCandidateNames(string memory _name) public {
        candidateName.push(_name);
    }

    function getCandidateNames() public view returns (string[] memory){
        return candidateName;
    }
    
    function voting(string memory _candidateName) public {
        voteCount[_candidateName]++;
        voter[msg.sender] = _candidateName;
    }
}
