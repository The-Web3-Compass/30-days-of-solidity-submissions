// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation {
    string[] public CandidatesName;
    mapping(string => uint256) public VoteCount;
    mapping(address => bool) public VoterList;

    function HasCandidate(string memory _CandidateName) private view returns  (bool) {
        for (uint i=0; i<CandidatesName.length;i++) 
        {
            // TypeError：内置二元运算符 == 无法应用于 string storage ref 类型与 string memory 类型
            // 该错误是 Solidity 中 字符串类型比较的典型类型不匹配错误，核心原因是开发者试图用 == 运算符直接比较两种「数据位置不同」的字符串：
            // 一种是存储在合约持久化存储中的 string storage ref（storage 引用类型），另一种是临时存储在内存中的 string memory（memory 临时类型）——Solidity 明确禁止直接对不同数据位置的字符串使用 == 比较。
            // 
            // string memory storedStrInMemory = CandidatesName[i];
            // if (storedStrInMemory == _CandidateName){
            //     return ;
            // }
            if(keccak256(bytes(CandidatesName[i])) == keccak256(bytes(_CandidateName))){
                return true;
            }
        }
        return false;
    }

    function AddCandidate(string memory _CandidateName) public {
        if(!HasCandidate(_CandidateName)){
            CandidatesName.push(_CandidateName);
            VoteCount[_CandidateName] = 0;
        }
    }

    function getCandidatesName() public view returns(string[] memory){
        return CandidatesName;
    } 

    function Vote(address _voter,string memory _CandidateName) public {
        if(HasCandidate(_CandidateName) && !VoterList[_voter]){
            VoteCount[_CandidateName] +=1;
            VoterList[_voter] = true;
        }
    }

    function getVote(string memory _CandidateName) public view returns ( uint256 ) {
        return VoteCount[_CandidateName];
    }

}