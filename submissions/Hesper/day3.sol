//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation{

    string[]public candidateNames;
    mapping(string => uint256) voteCount;

    function addCandidate(string memory _candidateNames) public{
    
        candidateNames.push(_candidateNames); // why starts from 0 while mapping: 0 - sarah, 1 - john,etc.
        voteCount[_candidateNames] = 0; 
    }

// retrieving the list of candidates

    function getNames() view public returns(string[] memory ){
        return candidateNames;
        // GPT一开始说不能直接写 return candidateNames;  solidity 不允许把storage数组直接转换成memory数组。但是可能是remix版本允许直接转译了。
        
    }
// vote for certain candidates

    function vote(string memory _candidateNames)public{
        voteCount [_candidateNames] += 1; //这个mapping是可以直接用于计数的。我本来想写 string[_candidateNames]但是发现不知道怎么+1.
    }


// retrieving the final votecount of candidates
    function getCount(string memory _candidateNames)public view returns(uint256){
        
        return voteCount[_candidateNames];
        //不能直接写return voteCount;上面的string和下面的voteCount数据类型不一样。
    }



}