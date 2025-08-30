// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasSaver {
    address public chairperson;
    mapping (address=>Voter) voters;
    uint winningProposalIndex;

    struct Voter {
        bool voted;
        uint248 voteIndex;
    }

    struct Proposal {
        string proposal;
        uint32 voteCount;
    }

    Proposal[] public proposals;

    error NotChairperson();

    constructor (address _chairperson) {
        chairperson = _chairperson;
    }

    function _isChairperson() internal view returns (bool) {
      if(msg.sender == chairperson) return NotChairperson();
    }

    function addVoter(address _voter)  {
        _isChairperson();
        require (_voter != address(0), "IZ0");
        require(!voters[_voter].voted, "Voter already exists");
        voters[_voter] = Voter({voted: false, voteIndex: 0});
    }

    function addProposal(string calldata _proposal) external {
        _isChairperson();
        require(bytes(_proposal).length > 0, "Proposal cannot be empty");
        proposals.push(Proposal({name: _name, voteCount: 0}));
    }

    function vote(uint248 _proposalIndex) external {
        Vooter storage voter = voters[msg.sender];
        require(voter.voted == false, "You have already voted");
        require(_proposalIndex < proposals.length, "Invalid proposal index");

        voter.voted = true;
        voter.voteIndex = _proposalIndex;
        unchecked {
            proposals[_proposalIndex].voteCount++;
        }

        if (proposals[_proposalIndex].voteCount > proposals[winningProposalIndex].voteCount) {
            winningProposal = _proposalIndex;
        }
    }

    function getWinningProposal() external view returns (string memory winningProposalName) {
        Proposal storage winningProposal = proposals[winningProposalIndex];
        return winningProposal.proposal;
    }
}
