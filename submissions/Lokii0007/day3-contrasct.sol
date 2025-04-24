// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidates;
    mapping(string => uint256) voteCount;

    function addCandidate(string memory _name) public {
        candidates.push(_name);
        voteCount[_name] = 0;
    }

    function vote(string memory _candidateName) public {
       voteCount[_candidateName]++;
    }

    function getCandidates() public view returns(string[] memory){
        return candidates;
    }

    function getVote(string memory _candidateName) public view returns(uint256){
        return voteCount[_candidateName];
    }
}