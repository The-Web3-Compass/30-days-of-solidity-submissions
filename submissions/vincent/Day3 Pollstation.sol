//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Pollstation{

    string[] public candidateNames;
    mapping (string => uint256) voteCount;

    function add(string memory newcandidateName) public{
        candidateNames .push(newcandidateName);
        voteCount[newcandidateName]=0;
    }

    function getcandidateNames()public view returns(string [] memory) {
        return candidateNames;
    }

    function vote(string memory newcandidateName)public{
        voteCount[newcandidateName]+= 1;
    }

    function getvote(string memory newcandidateName) public view returns(uint256){
        return voteCount[newcandidateName];
    }

}
