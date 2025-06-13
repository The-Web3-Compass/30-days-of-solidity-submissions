// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    mapping(string => uint256) voteCount;
    
    function addCandidates(string memory _candidateNames) public{  //_something 通常是函数的参数。
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0 ;
    }

    function vote(string memory _candidateNames) public {
        voteCount[_candidateNames]++;
    }

    function getCandidateNames() public view returns(string[] memory){
        return candidateNames;
    }

    function getVote(string memory _candidateNames) public view returns(uint256){
        return voteCount[_candidateNames];
    }

    function getfullVote() public view returns(string[] memory, uint256[] memory){
        uint256[] memory votesum = new uint256[](candidateNames.length); //在 Solidity 中，memory 类型的数组不能像 JavaScript 那样直接 push，必须一开始就确定长度并用 new 创建，所以要写成 new uint256[](length)
        //Solidity 是静态类型语言，创建内存数组时必须显式指定其长度（不像动态语言那样可以自动扩展），所以语法上必须用 new。
        
        for(uint256 i; i<candidateNames.length; i++){
            votesum[i] = voteCount[candidateNames[i]];
        }

        return (candidateNames, votesum);
    }
}
