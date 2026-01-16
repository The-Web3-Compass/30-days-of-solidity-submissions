// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract pollstation{
    
    string[] public candidatenames;
    mapping ( string => uint256 ) public votescount;

    function addcandidatenames(string memory _candidatenames) public {
        candidatenames.push(_candidatenames);
        votescount[_candidatenames] = 0;
    }
    
    function vote(string memory _candidatenames) public {
        votescount [_candidatenames]++;
    }

    function getcandidatenames () public view returns (string[] memory){
    return candidatenames;
    }

    function getvote(string memory _candidatenames) public view returns (uint256){
     return votescount [_candidatenames];
    }

}
