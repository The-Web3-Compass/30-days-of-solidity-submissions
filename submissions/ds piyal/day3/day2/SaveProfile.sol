// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SaveProfile {
    string name;
    string bio;
    uint256 age;
    string profession;

    function AddInfo (string memory _name, string memory _bio, uint256 _age , string memory _profession) public {
        name = _name;
        bio = _bio;
        age= _age ;
        profession =  _profession;
    }
    function getInfo() public view returns(string memory , string memory,uint256,string memory){
        return (name,bio,age,profession);

}

}