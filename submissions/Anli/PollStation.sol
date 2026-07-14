//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract PollStation{
    //想一下要做什么？0.声明string candidates，uint voteCount=0 1. 添加candidates， 初始化votecount=0 
    //1. 投票要显示candidates 2. 投票计数 3.把计数显示出来
    string[] public Candidates; //for string: Only need to add saving location when retrieve! 
    mapping (string => uint256) VoteCount ; 
    
    function AddCandidates(string memory _Candidates) public { //函数一定要是public吗？否则报错
        Candidates.push(_Candidates); //对于Array的录入，需要使用 Value.push(_Value)；
        VoteCount[_Candidates] = 0;//[] 用于数组索引或映射的键访问
    }

    function ShowCandidates() public view returns(string[] memory) { //在表示这个函数会涉及什么类型的value的时候不需要标明具体是哪个
        return Candidates; //函数内部不需要描述Variables的性质和位置
    }

    function Vote(string memory _Candidates) public {
        VoteCount[_Candidates]++;
    }

    function ShowVoteCount(string memory _Candidates) public view returns(uint256){ //mapping is not Array
        return VoteCount[_Candidates];
    }
}