pragma solidity ^0.8.20;

contract Profile{
    string public name;
    string public bio;
    bool public exists = false;

    function saveProfile(string memory userName, string memory userBio) public returns (string memory){
        name = userName;
        bio = userBio;
        exists = true;

        return "Profile saved Done!";
    }

    function getProfile() public view returns (string memory, string memory){
        if(!exists){
            return ("","");
        }
        return (name, bio);
    }
}