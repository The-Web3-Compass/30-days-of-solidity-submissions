// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title PollStation
/// @author shivam
/// @notice A simple contract to do voting with predefined candidates
contract PollStation {
    /// @notice Represents a candidate
    struct Candidate {
        string name;
        uint64 voteCount;
    }

    /// @notice Error thrown when an invalid candidate index is provided
    /// @param _index The invalid index that was provided.
    error CandidateIndexInvalid(uint _index);

    /// @notice Error thrown when a user tries to vote more than once
    /// @param _user The address of the user
    error AlreadyVoted(address _user);

    /// @notice Error thrown when a user has not voted and tries to retrieve vote details
    /// @param _user The address of the user
    error NotVoted(address _user);

    /// @notice Event emitted when a vote is cast
    /// @param _user The address of the user who voted.
    /// @param _candidateIndex The index of the candidate the user voted for
    event Voted(address indexed _user, uint indexed _candidateIndex);

    /// @notice Array with all candidates
    Candidate[] private candidates;

    /// @notice Mapping of user's address to the index of the candidate voted for, offset by 1.
    /// @dev Stores `candidate index + 1`. 0 means the user has not voted. The offset allows identifying when user has not voted.
    mapping (address => uint) private userVotes;

    /// @notice Initializes the contract by adding default candidates
    constructor() {
        // Add some initial candidates
        candidates.push(Candidate("Alice", 0));
        candidates.push(Candidate("Bob", 0));
        candidates.push(Candidate("Charlie", 0));
    }

    /// @notice Gets the total number of candidates
    /// @return count The count of candidates
    function getCandidatesCount() public view returns (uint) {
        return candidates.length;
    }


    /// @notice Get the details of a specific candidate by index
    /// @param _index The index of the candidate to get (0-based)
    /// @return name The name of the candidate
    /// @return voteCount The current vote count for the candidate
    /// @custom:error CandidateIndexInvalid if `_index` is out of bounds
    function getCandidate(uint _index) public view returns (string memory name, uint64 voteCount) {
        if (_index >= candidates.length) {
            revert CandidateIndexInvalid(_index);
        }
        name = candidates[_index].name;
        voteCount = candidates[_index].voteCount;
    }

    /// @notice Gets the vote cast by the caller (`msg.sender`)
    /// @return candidateIndex The index of the candidate voted for
    /// @custom:error NotVoted if user has not voted
    function getVote() public view returns (uint) {
        if (userVotes[msg.sender] == 0) {
            revert NotVoted(msg.sender);
        }
        return userVotes[msg.sender]-1;
    }

    /// @notice Finds the candidate with the maximum number of votes. In case of a tie, the candidate with the higher index is returned.
    /// @dev Iterates through all candidates to find the one with the highest vote count
    /// @return _index Index of candidate with most votes
    /// @return _votes Maximum number of votes
    function maxVotes() public view returns (uint _index, uint64 _votes) {
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > _votes) {
                _index = i;
                _votes = candidates[i].voteCount;
            }
        }
    }


    /// @notice Casts the vote by caller (`msg.sender`) to the candidate specified by index.
    /// @dev A user can only vote once
    /// @param _index The index of the candidate to vote for
    /// @custom:event Voted if the vote is cast successfully
    /// @custom:error CandidateIndexInvalid if `_index` is out of bounds
    /// @custom:error AlreadyVoted if `mmsg.sender` has already voted
    function vote(uint _index) public {
        if (_index >= candidates.length) {
            revert CandidateIndexInvalid(_index);
        }
        // Check if user has already voted (userVotes stores index + 1, 0 means not voted)
        if (userVotes[msg.sender] != 0) {
            revert AlreadyVoted(msg.sender);
        }

        // Record the vote (store index + 1)
        userVotes[msg.sender] = _index + 1;
        // Increment the candidate's vote count
        candidates[_index].voteCount += 1;

        // Emit the event
        emit Voted(msg.sender, _index);
    }
}