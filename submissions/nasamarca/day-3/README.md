# Week 1 — Solidity Fundamentals (Day 3)
## Challenge: PollStation.sol

**Author:** Nadiatus Salam  
**Contract file:** `PollStation.sol`

### Challenge Recap
This challenge focuses on managing structured data and relationships on the blockchain:

- **Arrays (`uint[]`, structs)**: Storing lists of data (candidates).
- **Mappings (`mapping`)**: Creating associations (who voted for whom).
- **Structs**: Grouping related data (candidate name + vote count).
- **Voting Logic**: Preventing double voting and tracking results.

The goal is to build a digital "polling station" where users can add candidates and vote for them by ID.

---

## Contract Overview

`PollStation` is a voting contract that demonstrates efficient data storage and retrieval.

### Key Features:
1.  **Candidate Management**: Add candidates with names. Each gets a unique ID (its index in the array).
2.  **Secure Voting**:
    - One person, one vote (enforced by `mapping(address => bool)`).
    - Checks if the candidate ID exists.
3.  **Transparency**:
    - `userVotedFor`: Publicly check who an address voted for.
    - `getCandidate`: Retrieve name and current vote count.
    - Events (`Voted`, `CandidateAdded`) for off-chain tracking.
4.  **Efficiency**:
    - Uses `struct` to keep name and votes together.
    - Uses `unchecked` math for gas-optimized counters.
    - Uses custom errors (`AlreadyVoted`, `InvalidCandidateId`) to save gas on reverts.

---

## Technical Highlights

### 1. Structs & Arrays
Instead of just storing numbers, we use a `struct` to group data:
```solidity
struct Candidate {
    string name;
    uint256 voteCount;
}
Candidate[] public candidates;
```
- **Why?** It keeps the code organized. `candidates[0]` gives us everything about the first candidate.

### 2. Mappings
```solidity
mapping(address => uint256) public userVotedFor;
mapping(address => bool) public hasVoted;
```
- **Why?** Mappings are like hash tables. They allow instant lookups (O(1) complexity) to check if `msg.sender` has voted, without looping through an array.

### 3. Gas Optimization (Unchecked)
```solidity
unchecked {
    candidates[_candidateId].voteCount++;
}
```
- **Why?** Since Solidity 0.8.0, arithmetic is checked for overflow by default (which costs gas). Voting counts will realistically never reach 2^256, so `unchecked` skips this check to save gas.

---

## How To Test (Remix Quick Guide)

1. Open Remix: https://remix.ethereum.org  
2. Create `PollStation.sol` and paste the contract code.
3. **Compile** with version `0.8.24`.
4. **Deploy** to Remix VM.
5. **Interact**:
   - **Add Candidates**: Call `addCandidate("Alice")`, then `addCandidate("Bob")`.
   - **Check Candidates**: Call `getCandidate(0)` → Returns "Alice", 0 votes.
   - **Vote**: Call `vote(0)` (voting for Alice).
   - **Verify Vote**: Call `getCandidate(0)` → Returns "Alice", 1 vote.
   - **Check Voter**: Call `userVotedFor(YOUR_ADDRESS)` → Returns 0.
   - **Double Vote**: Try calling `vote(1)` with the same address → Reverts with `AlreadyVoted`.