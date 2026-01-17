// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    error PollStation__UserAllreadyExist();
    error PollStation__UserAllreadyVoted();

    struct s_candidate {
        string name;
        uint256 age;
        bool isUser;
        address accountAddress;
    }

    struct s_origination {
        string name;
        uint256 totalVotes;
        address[] candidates;
    }

    s_origination[] private originations;
    mapping(address => s_candidate) public s_candidateProfile;
    mapping(address => mapping(uint256 => bool)) public isAllreadyVoted;

    function new_user(string memory _name, uint256 _age) public {
        s_candidate memory user = s_candidateProfile[msg.sender];
        if (user.isUser == true) revert PollStation__UserAllreadyExist();
        s_candidateProfile[msg.sender] = s_candidate({name: _name, age: _age, isUser: true, accountAddress: msg.sender});
    }

    function new_origination(string memory _name) public {
        originations.push(s_origination({name: _name, totalVotes: 0, candidates: new address[](0)}));
    }

    function vote(uint256 _index) public {
        if (isAllreadyVoted[msg.sender][_index] == true) revert PollStation__UserAllreadyVoted();
        isAllreadyVoted[msg.sender][_index] = true;
        // s_candidate memory user = s_candidateProfile[msg.sender];
         originations[_index].candidates.push(msg.sender);
        // origination.candidates.push(msg.sender);
    }
    function getCandidates(uint256 _index) public view returns (address[] memory) {
    return originations[_index].candidates;
}
}
