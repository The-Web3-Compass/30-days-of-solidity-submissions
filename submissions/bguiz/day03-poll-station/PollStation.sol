// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title PollStation
 * @dev Let's build a simple polling station!
 * Users will be able to vote for their favorite candidates.
 * You'll use lists (arrays, `uint[]`) to store candidate details.
 * You'll also create a system (mappings, `mapping(address => uint)`) to remember who (their `address`) voted for which candidate.
 * Think of it as a digital voting booth.
 * This teaches you how to manage data in a structured way.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 3
 */
contract PollStation {
    string[] public choices;
    mapping(uint256 => uint256) public votes;
    bool public hasVotingStarted = false;
    mapping(address => bool) public hasVoted;

    function addChoice(string memory name) public {
        require(!hasVotingStarted, "cannot add choices after voting has begun");
        choices.push(name);
    }

    function vote(uint256 choiceIndex) public {
        require(choiceIndex < choices.length, "cannot vote for a choice that does not exist");
        require(!hasVoted[msg.sender], "cannot vote again");
        hasVotingStarted = true;
        hasVoted[msg.sender] = true;
        votes[choiceIndex] += 1;
    }
}
