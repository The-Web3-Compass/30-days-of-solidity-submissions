//SPDX-License-Identifier:MIX
pragma solidity^0.8.0;

 contract Pollstation{

    string[] public CandidateNames;
    mapping(string=>uint256) public votecount;

    function addcandidate(string memory _CandidateNames)public{
        CandidateNames.push(_CandidateNames);
        votecount[_CandidateNames]=0;
    }
    function votecandidate(string memory _CandidateNames) public{
        votecount[_CandidateNames]++;

    }
    function candidatelist() public view returns(string[] memory){
        return(CandidateNames);
    }
    function getresults(string memory _CandidateNames) public view returns(uint256){
        return(votecount[_CandidateNames]);

    }
    

    }
