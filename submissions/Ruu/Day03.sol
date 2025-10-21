//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract PollStation {

    string[] public CandidateNames;

    mapping (string => uint256) public  VoteCount;

    function AddCandidates(string memory _CandidateNames_) public {
        CandidateNames.push(_CandidateNames_);
        VoteCount[_CandidateNames_] = 0;
    }

    function Vote(string memory _CandadateNames_) public {
        VoteCount[_CandadateNames_]++;
    }

    function GetCandidateNames() public view returns(string[] memory) {
        return CandidateNames;
    }

    function GetVote(string memory _CandidateNames_) public view returns(uint256){
        return VoteCount[_CandidateNames_];
    }

}
