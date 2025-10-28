// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Governance
 * @dev Build a system for voting on proposals.
 * You'll learn how to create a digital organization where members can vote,
 * demonstrating decentralized governance.
 * It's like a digital democracy, showing how to create DAOs.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 28
 */
contract Governance is ReentrancyGuard, Ownable {
    using SafeCast for uint256;

    struct Proposal {
        uint256 id;
        uint256 numAccept;
        uint256 numDeny;
        uint256 completeTs;
        uint256 executeTs;
        address executeTarget;
        bytes executeCalldata;
        address proposer;
        string description;
    }

    uint256 public proposalCount;
    uint256 public proposalPrice;
    uint256 public voteDuration;
    uint256 public executeDuration;
    uint256 public quorum; // basis points, e.g. 100 = 1%
    IERC20 public govToken;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    constructor(
        IERC20 _govToken
    ) ReentrancyGuard() Ownable(msg.sender) {
        govToken = _govToken;
        voteDuration = 60;
        executeDuration = 60;
        quorum = 30_00; // 30%
        proposalPrice = 100; // 100 governance tokens
    }

    function addProposal(
        address _target,
        bytes memory _calldata,
        string memory _description
    ) public nonReentrant returns(uint256 proposalId) {
        proposalId = ++proposalCount;
        proposals[proposalId] = Proposal({
            id: proposalId,
            numAccept: 0,
            numDeny: 0,
            completeTs: block.timestamp + voteDuration,
            executeTs: 0,
            executeTarget: _target,
            executeCalldata: _calldata,
            proposer: msg.sender,
            description: _description
        });
        return proposalId;
    }

    function voteProposal(
        uint256 proposalId,
        bool accept
    ) public nonReentrant {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp < p.completeTs, "after complete");
        require(!voted[proposalId][msg.sender], "already voted");
        uint256 govTokenBalance = govToken.balanceOf(msg.sender);
        require(govTokenBalance > 0, "not a member");
        uint256 weight = govTokenBalance;
        if (accept) {
            p.numAccept += weight;
        } else {
            p.numDeny += weight;
        }
        voted[proposalId][msg.sender] = true;
    }

    function completeProposal(
        uint256 id
    ) public nonReentrant {
        Proposal storage p = proposals[id];
        require(block.timestamp > p.completeTs, "still open");
        require(p.executeTs > 0, "already executed");

        uint256 quorumForProposal = govToken.totalSupply() * quorum / 100_00;
        if (
            (p.numAccept + p.numDeny >= quorumForProposal) &&
            (p.numAccept > p.numDeny)
        ) {
            p.executeTs = block.timestamp + executeDuration;
        }
    }

    function executeProposal(
        uint256 id
    ) public nonReentrant {
        Proposal storage p = proposals[id];
        require(block.timestamp > p.executeTs, "not yet");
        (bool done, bytes memory returnData) = p.executeTarget.call(p.executeCalldata);
        require(done, string(returnData));
    }
}
