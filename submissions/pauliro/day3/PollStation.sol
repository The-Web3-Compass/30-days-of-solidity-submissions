// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
 /*
    Users will be able to vote for their favorite candidates. 
    You'll use lists (arrays, `uint[]`) to store candidate details. 
    You'll also create a system (mappings, `mapping(address => uint)`) to remember who (their `address`) 
    voted for which candidate. 
 */


contract PollStation {
    
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    // List of candidates
    Candidate[] public candidates; 
    
    mapping (address =>bool) public hasVoted; // stores if the address has voted
    mapping (address => uint256) public voterChoice; // stores who voted for wich candidate
    // mapping (string => uint256) public nameToVotes;

    function addCandidates(string memory _candidateName) public{
        candidates.push(Candidate(_candidateName, 0));
    }
    function getCandidate(uint256 _number) public view returns (string memory) {
        return candidates[_number].name;
    }

    function getCandidateVotes(uint256 _number) public view returns (uint256) {
        return candidates[_number].voteCount;
    }
    
    function getTotalCandidates() public view returns (uint) {
        return candidates.length;
    }

    function vote(uint _canditateIndex) public {
        require(_canditateIndex < candidates.length, "Invalid Candidate");
        require(!hasVoted[msg.sender], "You already voted!");
        
        candidates[_canditateIndex].voteCount++;
        hasVoted[msg.sender] = true;
        voterChoice[msg.sender] = _canditateIndex;
        // nameToVotes[candidates[_canditateIndex].name] = candidates[_canditateIndex].voteCount;
    }
}
