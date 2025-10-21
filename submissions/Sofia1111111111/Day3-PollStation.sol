// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract PollStation{
    //存储候选者的信息
    string[] public candidates;
    uint256 voteCount;
    //使用mapping创建候选者和投票数的关联字典
    mapping(string=>uint256) public voteMap;

    //添加候选者信息
     function addCandidate(string memory _candidate) public {
        candidates.push(_candidate); 
        voteMap[_candidate] = 0;
     }

    //获取候选者名单
    function getCandidates()public view returns(string[] memory) {
        return candidates;

    }

    //往voteMap添加信息:开始投票
    function voteForCandidates(string memory _candidate) public {
        voteMap[_candidate] +=1;
    }

    

}
