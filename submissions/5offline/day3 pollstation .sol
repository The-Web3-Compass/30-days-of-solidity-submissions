//SPDX-License-Identifier:MIX
pragma solidity^0.8.0;

 contract Pollstation{

    string[] public CandidateNames;
    mapping(string=>uint256) public votecount;
    //mapping：映射，指用key来找value，像写礼帐一样，这个账簿每个不用的命名会找到不同的书，比如这本是吃饭，那本是礼物，不会mapping错数值
    //[]指的是数组

    function addcandidate(string memory _CandidateNames)public{
        CandidateNames.push(_CandidateNames);
        votecount[_CandidateNames]=0;
    }
    //添加一些candidates
    function votecandidate(string memory _CandidateNames) public{
        votecount[_CandidateNames]++;

    }
    //给xx投票
    function candidatelist() public view returns(string[] memory){
        return(CandidateNames);
    }
    function getresults(string memory _CandidateNames) public view returns(uint256){
        return(votecount[_CandidateNames]);

    }
    

    }



