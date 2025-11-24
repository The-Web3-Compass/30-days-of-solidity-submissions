// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract pollstation{
    string[] public candidateNames;
    mapping(string=>uint256)voteCount;

//添加候选人姓名，存入数组，票数映射初始化
    function addcandidateNames(string memory _candidateNames)public {
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }
//获取数组中可选人
    function getcandidateNames()public view returns  (string[] memory){
        return candidateNames;
    }

//给对应候选人投票
    function vote(string memory _candidatename)public {
        voteCount[_candidatename] +=1;
    }
    
//获取投票结果
    function getvote(string memory _candidatename) public view returns(uint256){
        return voteCount[_candidatename];
    }
}
