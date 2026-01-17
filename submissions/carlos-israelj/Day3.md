# Day 3: PollStation Contract

## Description
A simple voting contract that allows users to vote for candidates. Introduces arrays and mappings for structured data management.

## Features
- ✅ Vote for candidates using array indices
- ✅ Track votes with dynamic array (uint256[])
- ✅ Prevent double voting with mappings
- ✅ Record voter choices (mapping address → candidate)
- ✅ Track voting status (mapping address → bool)
- ✅ Add new candidates dynamically
- ✅ Get winner with most votes
- ✅ View all votes and individual candidate votes
- ✅ Complete NatSpec documentation
- ✅ Custom errors for gas efficiency
- ✅ Events for transparency

## Concepts Learned
- **Arrays**: Dynamic uint256[] for storing vote counts
- **Mappings**: address → uint256 and address → bool
- **Constructor**: Initialize contract with parameters
- **Loops**: For loop to find winner
- **Multiple returns**: Return multiple values from functions
- **Array operations**: push(), length, indexing

## State Variables
- `s_votes` (uint256[]): Array of vote counts per candidate
- `s_voterToCandidate` (mapping): Tracks which candidate each address voted for
- `s_hasVoted` (mapping): Tracks if an address has voted
- `s_totalVotes` (uint256): Total number of votes cast

## Functions
- `vote(uint256)`: Cast a vote for a candidate
- `addCandidate()`: Add a new candidate to the poll
- `getVotes(uint256)`: Get votes for specific candidate
- `getAllVotes()`: Get all vote counts
- `getCandidateCount()`: Get number of candidates
- `getVoterChoice(address)`: Check who an address voted for
- `hasVoted(address)`: Check if address has voted
- `getWinner()`: Get candidate with most votes

## Usage Example

// Deploy with 3 candidates
PollStation poll = new PollStation(3);// Vote for candidate 0
poll.vote(0);// Add new candidate
poll.addCandidate();// Get winner
(uint256 winnerId, uint256 voteCount) = poll.getWinner();

## Author
Carlos I Jimenez
