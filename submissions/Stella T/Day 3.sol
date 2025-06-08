// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract pollstation{
    string[] public candidatename;
    mapping(string=>uint256) votenumber;
    mapping(string =>bool) checkname;
    mapping(address =>bool) ifvote;
 function addcandidate(string memory _candidatename) public{
    require(!checkname[_candidatename], "Candidate already exists");
    candidatename.push(_candidatename);
    checkname[_candidatename]=true;
    votenumber[_candidatename]=0;
 }
 function getname() public view returns(string[] memory){
    return candidatename;
 }
 function vote(string memory _candidatename) public {
    require(checkname[_candidatename],"not a valid candidate");
    require(!ifvote[msg.sender],"you already voted");
    votenumber[_candidatename]+=1;
 }
 function getvote(string memory _candidatename) public view returns(uint256){
 return votenumber[_candidatename];
 }
}