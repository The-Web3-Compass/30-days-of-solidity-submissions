// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract PollStation{

    string[] public candidateNames;
    mapping(string => uint256) public voteCount;

    //需要创建一个候选人名单，这名单是谁都能创建的。即：我可以任意推举候选人，我推举的人都会被其他人看到并进行投票
    function createCandidateList(string memory _candidateNames) public{
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
    }
    //获取候选人名单
    function retrieveCandidateList() public view returns(string[] memory){
        return(candidateNames);
    }
    //给候选人投票：根据名字
    function vote(string memory _candidateNames) public{
        voteCount[_candidateNames] ++;
    }
    //获取某个候选人的得票数：根据名字
    function retrieveVote(string memory _candidateNames) public view returns(uint256){
        return voteCount[_candidateNames];
    }

}