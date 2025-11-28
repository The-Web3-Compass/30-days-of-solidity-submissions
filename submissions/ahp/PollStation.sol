//SPDX-License-indentifier: MIT

pragma solidity ^0.8.0;

contract pollstation {
    string[] public condidatenames;
    mapping (string=>uint256) public voteCount;
    function addcondidates(string memory _condidatenames) public {
        condidatenames.push(_condidatenames);
        voteCount[_condidatenames] = 0;
    }

    function vote(string memory _condidatenames) public {
        voteCount[_condidatenames]++;

    }
    function getcandidatenames() public view returns ( string[] memory ) {
        return condidatenames;
    }
    function getvote(string memory _condidatenames) public view returns (uint256) {
        return voteCount[_condidatenames];
    }

}