// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract PollStation {
    address private admin;
    uint private currentID;
    mapping (uint=>Candidate) private candidateId;
    mapping(address=>uint) public votes;
    struct Candidate {
        uint ID;
        string name;
        string slogan;
        uint vote_count;
    }
    error AlreadyVoted();
    error CandidateNotFound();
    event CandidateAdded(uint indexed id, string name);
    event Voted(address indexed voter, uint indexed id);

    constructor(){
        admin=msg.sender;
    }

    modifier Onlyadmin {
    require(msg.sender==admin, "Only admin can set candidates");
    _;
    }

    function addcandidates (string memory name,string memory slogan) external Onlyadmin {
         bytes memory nameBytes = bytes(name);
        if (nameBytes.length == 0) revert("Empty name");
        currentID++;
        candidateId[currentID]=Candidate(currentID,name,slogan,0);
        emit CandidateAdded(currentID, name);
    }

    function getcandidate(uint id) public view returns(uint _id, string memory name, string memory slogan, uint vote_count){
        Candidate memory c= candidateId[id];
        if (c.ID == 0) revert CandidateNotFound();
        return(id,c.name,c.slogan,c.vote_count);
    }

    function vote(uint id) external{
        if (votes[msg.sender] != 0) revert AlreadyVoted();
        Candidate storage candidate = candidateId[id];
        if (candidate.ID == 0) revert CandidateNotFound();
        votes[msg.sender]=id;
        candidate.vote_count++;
        emit Voted(msg.sender, id);
    }
}