// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{

  string [] public candidateNames;

  mapping (string=>uint256) voteCount;   

  function addcandidateNames(string memory _candidateNames) public {

  candidateNames.push(_candidateNames);   //将候选人姓名推入数组

  voteCount [_candidateNames]=0;  //定义起始值
  }

  function getcandidateNames () public view returns (string[] memory) {
    return candidateNames;
  }

  function vote (string memory _candidateNames) public {
    //在映射中，中括号是用来通过 “键” 获取或修改 “值” 的操作符
  voteCount [_candidateNames] +=1 ;  //voteCount[_candidateNames] = voteCount[_candidateNames] + 1;
  }

  function getvote(string memory _candidateNames) public view returns (uint256) {
    return voteCount[_candidateNames]  ;
  }
}