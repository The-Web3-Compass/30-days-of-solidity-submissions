//SPDX-License-Identifier-:MIT

pragma solidity ^0.8.0;

contract PollStation{
   string[] public CandidateNames;
   mapping(string => uint256)  VoteCount;

   function AddCandidates(string memory _CandidateNames) public{
    CandidateNames.push(_CandidateNames);
    VoteCount[_CandidateNames]=0;
   }


   function vote(string memory _CandidateNames) public {
   VoteCount[_CandidateNames]++;
   }

   function GetCandidateNames() public view returns(string[] memory){
    return CandidateNames;
   }

   function GetVotes(string memory _CandidateNames)public view returns(uint256){
    return VoteCount[_CandidateNames];
   }


}
