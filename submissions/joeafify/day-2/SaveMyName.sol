// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

contract SaveMyName {
    // Owner of the contract
    address public owner;

    // Declaring variables
    string public name;
    string public bio;

    event DataSaved(string name, string bio);

    // Set the deployer as the initial owner
    constructor() {
      owner = msg.sender;
    }

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
      require(msg.sender == owner, "Not authorized");
      _;
    }

    //Declaring a function
    function save(string memory _name, string memory _bio) public onlyOwner {
      require(bytes(_name).length > 0, "Name must not be empty");
      require(bytes(_bio).length > 0, "Bio must not be empty");

      name = _name;
      bio = _bio;
      emit DataSaved(_name, _bio);
    }

    function retrieve() public view returns (string memory, string memory) {
      return (name, bio);
    }
}