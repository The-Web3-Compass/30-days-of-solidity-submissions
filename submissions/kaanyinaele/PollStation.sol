// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimplePoll {
    // Array to hold vote counts for each option
    uint[] public votes;

    // Tracks if a user has voted and for which option
    mapping(address => bool) public hasVoted;

    // Constructor initializes the poll with N options
    constructor(uint _numOptions) {
        votes = new uint[](_numOptions);
    }

    // Vote for an option (by index)
    function vote(uint _option) public {
        require(!hasVoted[msg.sender], "You have already voted!");
        require(_option < votes.length, "Invalid option selected");

        votes[_option]++;
        hasVoted[msg.sender] = true;
    }

    // Get the total votes for an option
    function getVotes(uint _option) public view returns (uint) {
        require(_option < votes.length, "Invalid option selected");
        return votes[_option];
    }

    // Get total number of options
    function getNumOptions() public view returns (uint) {
        return votes.length;
    }
}
