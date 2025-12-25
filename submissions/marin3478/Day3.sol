//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidatenames;
    mapping(string=> uint256) public votecount;

    function addcandidates(string memory _candidatenames) public{
        candidatenames.push(_candidatenames);
        votecount[_candidatenames] =0;
    }

    function vote(string memory _candidatenames) public{
        votecount[_candidatenames]++;
    }

    function getcandidatenames() public view returns(string[] memory){
        return candidatenames;
    }

    function getvote(string memory _candidatenames) public view returns(uint256){
        return votecount[_candidatenames];
    }
}
