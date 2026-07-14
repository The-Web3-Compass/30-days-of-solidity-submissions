 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    string[] public candidateNames;
    mapping(string => uint256) public voteCount;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    event CandidateAdded(string _candidateName);
    event VoteCast(string _candidateName, uint256 _voteCount);

    function addCandidateNames(string memory _candidateNames) public onlyOwner {
        require(bytes(_candidateNames).length > 0, "Candidate name cannot be empty");
        candidateNames.push(_candidateNames);
        voteCount[_candidateNames] = 0;
        emit CandidateAdded(_candidateNames);
    }

    function getCandidateNames() public view returns (string[] memory) {
        return candidateNames;
    }

    function vote(string memory _candidateNames) public {
        require(
            bytes(_candidateNames).length > 0,
            "Candidate name cannot be empty"
        );
        require(
            contains(candidateNames, _candidateNames),
            "Candidate does not exist"
        );
        voteCount[_candidateNames]++;
        emit VoteCast(_candidateNames, voteCount[_candidateNames]);
    }

    function getVote(string memory _candidateNames) public view returns (uint256) {
        return voteCount[_candidateNames];
    }

    function contains(string[] memory array, string memory value)
        private
        pure
        returns (bool)
    {
        for (uint i = 0; i < array.length; i++) {
            if (keccak256(bytes(array[i])) == keccak256(bytes(value))) {
                return true;
            }
        }
        return false;
    }
}
