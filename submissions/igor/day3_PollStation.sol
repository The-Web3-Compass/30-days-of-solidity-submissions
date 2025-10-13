// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{
    string[] candidates;
    mapping (string => uint256) voteCount;

    function AddCandidate(string memory _name) public {
        candidates.push(_name);
        voteCount[_name] = 0;
    }

    function Vote(string memory _name) public {
        voteCount[_name]++;
    }

    function showCandidate() public view returns(string[] memory){
        return candidates;
    }

    function showCandidatesVote(string memory _name) public view returns(uint256){
        return voteCount[_name];
    }

}
