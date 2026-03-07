// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NotAuthorized();
error NotExistProfile();
error ExistedProfile(uint256);

contract SaveMyName {
    struct Person {
        string name;
        string bio;
    }

    uint256 private id;

    mapping(uint256 => Person) public idToPerson;
    mapping(uint256 => address) public idOwner;
    mapping(address => uint256) public ownerToId;
    mapping(address => bool) public hasProfile;

    modifier onlyAuthorized(uint256 _id) {
        if (_id >= id) revert NotExistProfile();
        if (idOwner[_id] != msg.sender) revert NotAuthorized();
        _;
    }

    modifier checkExistence() {
        address user = msg.sender;
        if (hasProfile[user]) revert ExistedProfile(ownerToId[user]);
        _;
    }

    function createProfile(string memory _name, string memory _bio) external checkExistence {
        uint256 currentId = id;
        idOwner[currentId] = msg.sender;
        ownerToId[msg.sender] = currentId;
        hasProfile[msg.sender] = true;
        idToPerson[currentId] = Person(_name, _bio);
        id = currentId + 1;
    }

    function modifyProfileInfo(uint256 _id, string memory _name, string memory _bio) external onlyAuthorized(_id) {
        idToPerson[_id].name = _name;
        idToPerson[_id].bio = _bio;
    }

    function getProfileInfo(uint256 _id) external view returns (string memory, string memory) {
        if (_id >= id) revert NotExistProfile();
        Person memory existencePerson = idToPerson[_id];
        return (existencePerson.name, existencePerson.bio);
    }
    }

    function getIndex() external view returns (uint256) {
        if (!hasProfile[msg.sender]) revert NotExistProfile();
        return ownerToId[msg.sender];
    }
    }

    function getNumberOfProfiles() external view returns (uint256) {
        return id;
    }
}
