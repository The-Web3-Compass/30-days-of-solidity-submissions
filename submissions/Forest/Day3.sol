//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    mapping(string =>uint256) public voteCount;

    function addCandidates(string memory _candidateNames) public{
        candidateNames.push(_candidateNames);
            voteCount[_candidateNames] = 0;
    }

    function vote(string memory _canditateNames) public {
        voteCount[_canditateNames]++;
    }

    function getCandidateNames() public view returns(string[] memory){
        return candidateNames;
    }

}
