// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SaveMyName {
    uint256 public id;
    mapping(uint256 => string) public idToName;
    mapping(uint256 => string) public idToBio;

    function CreateProfile(string memory _name, string memory _bio) public {
        idToName[id] = _name;
        idToBio[id] = _bio;
        id++;
    }

    function modifyProfileInfo(uint256 _id, string memory _name, string memory _bio) public {
        idToName[_id] = _name;
        idToBio[_id] = _bio;
    }

    function getProfileInfo(uint256 _id) public view returns (string memory profile) {
        profile = string.concat(idToName[_id], "-", idToBio[_id]);
        return profile;
    }
}
