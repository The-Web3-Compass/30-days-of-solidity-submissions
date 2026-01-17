// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{
    string[] candidateNames;
    //映射 把姓名和选票一一对应 键值对
    mapping(string=>uint256) voteCount;
    mapping(address=>bool) hasVoted;

    //加入候选人
    function addCandidate(string memory _candidateName)public{
        candidateNames.push(_candidateName);
        voteCount[_candidateName]=0;
    }
    //检查候选人是否存在
    function candidatesExist(string memory _name)internal view returns(bool){
        for(uint i=0;i<candidateNames.length;i++){
            if(keccak256(bytes(candidateNames[i]))==keccak256(bytes(_name))){
                return true;
                }
            }return false;
        }
    
    //投票
    function vote(string memory _candidateName)public {
        //判断候选人是否存在
        require(candidatesExist(_candidateName),"The candidate does not exist.");
        //判断是否已经投票
        require(!hasVoted[msg.sender],"Everyone has one chance,you have already voted.");
        //计票
        voteCount[_candidateName]++;
        //标记已投票
        hasVoted[msg.sender]=true;
        }
    //候选人列表
    function getCandidatesName() public view returns(string[] memory){
        return(candidateNames);
    }
    //查询候选人现有票数
    function getVote(string memory _candidateName) public view returns(uint256){
        return(voteCount[_candidateName]);
    }
}