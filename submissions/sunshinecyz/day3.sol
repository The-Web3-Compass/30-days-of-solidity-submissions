//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract PollStation{

    //声明变量
    string [] public CandidateName;
    mapping(string => uint256) VoteCount;

    //添加候选人
    function AddCandidateName(string memory _name ) public {
        CandidateName.push(_name);
        VoteCount[_name]=0;
    }

    //返回候选人列表
    function getCandidateNames() public view returns(string[] memory){
        return CandidateName;
    }

    //投票函数
    function Vote(string memory _name) public {
        VoteCount[_name]=VoteCount[_name]+1;
    }

    //查看候选人票数
    function getVoteCount(string memory _name ) view public returns(uint256 memory) {
        return VoteCount[_name];
    }

}