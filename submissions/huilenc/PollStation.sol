// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IPollStation {
    function addCandidate(string memory candidate) external;

    function voteForCandidate(string memory candidate) external;

    function showCandidatesList() external view returns (string[] memory);
}

contract PollStation is IPollStation {
    string[] public candidatesList;
    address owner;
    mapping(string candidate => uint256 votes) public candidateVotes;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner!");
        _;
    }

    function showCandidatesList() public view returns (string[] memory) {
        return candidatesList;
    }

    function addCandidate(string memory candidate) public onlyOwner {
        candidatesList.push(candidate);
    }

    function voteForCandidate(string memory candidate) public {
        candidateVotes[candidate]++;
    }
}
