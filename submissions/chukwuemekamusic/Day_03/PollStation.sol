// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract PollStation {
    error CandidateAlreadyExist();
    error CandidateDoesNotExist();
    error VoterAlreadyVoted();
    error NoCandidatesAvailable();
    error NoVoteCast();
    error VotingIsClosed();
    error NotOwner();
    error VotingIsStillOpen();

    struct Candidate {
        uint256 id;
        string name;
        string party;
        uint256 voteCount;
        bool isActive; // used later to delete candidate
    }

    uint256 public candidateCount;
    uint256 private votesCount;
    bool public isVotingOpen = true;
    address immutable i_owner;

    mapping(uint256 candidateId => Candidate) public candidates;

    mapping(address voters => uint256 candidateId) public voters;

    // mapping for unique candidates check with name & party
    mapping(bytes32 nameAndParty => bool) private uniqueCandidatesRegistered;

    event Vote(address indexed voter, string name);
    event CandidateCreated(uint256 indexed candidateId, string name, string party);

    modifier checkIfVotingIsOpen() {
        if (!isVotingOpen) revert VotingIsClosed();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    modifier checkIfCandidateExists(uint256 candidateId) {
        // because whenevery a candidate is added, they will be assigned an id that is not 0
        if (candidateId == 0 || candidateId > candidateCount || (candidates[candidateId].id == 0)) {
            revert CandidateDoesNotExist();
        }
        _;
    }

    modifier checkIfVoterVoted() {
        if (voters[msg.sender] != 0) revert VoterAlreadyVoted();
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function vote(uint256 _candidateId) public checkIfCandidateExists(_candidateId) checkIfVoterVoted checkIfVotingIsOpen {
        voters[msg.sender] = _candidateId;
        candidates[_candidateId].voteCount++;
        votesCount++;
        emit Vote(msg.sender, candidates[_candidateId].name);
    }

    function addCandidate(string memory _name, string memory _party) public {
        // Generate a unique hash for the name and party
        bytes32 uniqueKey = _generateUniqueCandidateKey(_name, _party);

        // CRITICAL FIX: Revert if the key ALREADY EXISTS
        if (uniqueCandidatesRegistered[uniqueKey]) revert CandidateAlreadyExist();

        candidateCount++;

        Candidate memory newCandidate =
            Candidate({id: candidateCount, name: _name, party: _party, voteCount: 0, isActive: true});

        candidates[candidateCount] = newCandidate;
        uniqueCandidatesRegistered[uniqueKey] = true; // Mark this unique key as registered
        emit CandidateCreated(candidateCount, _name, _party);
    }

    // HELPER FUNCTIONS
    function _generateUniqueCandidateKey(string memory _name, string memory _party) internal pure returns (bytes32) {
        // hash the candidate name and party
        return keccak256(abi.encode(_name, _party));
    }

    function setVoting(bool _isVotingOpen) public onlyOwner {
        isVotingOpen = _isVotingOpen;
    }

    // function setVoting(bool _isVotingOpen) public onlyOwner {
    //     // Only allow setting to false (closing voting)
    //     // Once closed, it cannot be reopened
    //     if (!_isVotingOpen) {
    //         isVotingOpen = false;
    //     }
    // }

    // GETTER FUNCTIONS

    function getCandidate(uint256 _candidateId)
        public
        view
        checkIfCandidateExists(_candidateId)
        returns (Candidate memory)
    {
        return candidates[_candidateId];
    }

    function getAllCandidates() external view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidateCount);

        for (uint256 i = 0; i < candidateCount; ++i) {
            allCandidates[i] = candidates[i + 1];
        }
        return allCandidates;
    }

    // WINNERS IN CASE OF TIE
    function getWinners() public view returns (Candidate[] memory) {
        if (candidateCount == 0) revert NoCandidatesAvailable();
        if (votesCount == 0) revert NoVoteCast();
        if (isVotingOpen) revert VotingIsStillOpen();

        uint256 highestVoteCount = 0;
        uint256 winnerId = 1;
        uint256 tieCount = 0;

        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount > highestVoteCount) {
                highestVoteCount = candidates[i].voteCount;
                winnerId = i;
                tieCount = 1; // Reset count to current candidate
            } else if (candidates[i].voteCount == highestVoteCount) {
                tieCount++;
            }
        }

        Candidate[] memory winners = new Candidate[](tieCount);
        if (tieCount > 1) {
            uint256 index = 0;
            for (uint256 i = 1; i <= candidateCount; i++) {
                if (candidates[i].voteCount == highestVoteCount) {
                    winners[index] = candidates[i];
                    index++;
                }
            }
        } else {
            winners[0] = candidates[winnerId];
        }

        return winners;
    }

    function hasVoted(address _voter) external view returns (bool) {
        return (voters[_voter] != 0);
    }

    function getVoterChoice(address _voter) external view returns (Candidate memory) {
        uint256 _candidateId = voters[_voter];
        if (_candidateId == 0) revert NoVoteCast();
        return candidates[_candidateId];
    }


    function getTotalVotes() external view returns (uint256) {
        return votesCount;
    }

}
