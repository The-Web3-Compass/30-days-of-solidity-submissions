// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title GasSaver
 * @dev Build a simple voting system where users can vote on proposals.
 * Your challenge is to make it as gas-efficient as possible.
 * Optimize how you store voter data, handle input parameters, and design functions.
 * You'll learn how `calldata`, `memory`, and `storage` affect gas usage and
 * discover small changes that lead to big savings.
 * It's like designing a voting machine that runs faster and cheaper without losing accuracy.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 12
 */
contract GasSaver {
    event ProposalCreated(uint32 indexed proposalId, bytes32 namehash);
    event VoteCasted(uint32 indexed proposalId, address voter);

    uint32 proposalCount = 0;
    mapping(uint32 => Proposal) proposals;
    mapping(address => uint256) voteHistories;

    struct Proposal {
        bytes32 name; // hash of name
        uint32 votes; // total votes for this proposal
        uint32 startTime; // unix timestamp in seconds
        uint32 endTime; // unix timestamp in seconds
        bool passed; // whether is succeeded in reaching quorum (and can be executed)
    }

    function createProposal(string memory name, uint32 duration) public returns(uint32 proposalId) {
        require(duration >= 30, "duration lower than permitted minimum");

        bytes32 namehash = keccak256(bytes(name));
        Proposal memory p = Proposal({
            name: namehash,
            votes: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            passed: false
        });

        proposalId = ++proposalCount;
        proposals[proposalId] = p;

        emit ProposalCreated(proposalId, namehash);
    }

    function vote(uint32 proposalId) public {
        require(proposalId < proposalCount, "no proposal with this ID");
        uint32 nowTs = uint32(block.timestamp);
        Proposal memory p = proposals[proposalId];
        require(nowTs >= p.startTime && nowTs < p.endTime, "cannot vote outside of voting period");

        uint256 votePositionalBit = 1 << proposalId;
        uint256 voterHistory = voteHistories[msg.sender];
        require((voterHistory & votePositionalBit) == 0, "cannot vote again for same proposal");

        voteHistories[msg.sender] = (voterHistory | votePositionalBit);

        proposals[proposalId].votes += 1;

        emit VoteCasted(proposalId, msg.sender);
    }
}
