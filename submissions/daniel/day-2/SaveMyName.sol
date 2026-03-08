// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract SaveMyName {

    struct User {
        string name;
        string description;
    }

    mapping(address => User) public users;


    function save(string memory _name, string memory _description) public {
        users[msg.sender] = User(_name, _description);
    }

    function retrieve() public view returns (string memory, string memory) {
        User memory user = users[msg.sender];
        return (user.name, user.description);
    }
}
