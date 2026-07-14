//SPDX-License-Identifier:MIT

pragma solidity 0.8.0;

contract SaveMyName {

    string name;
    string bio;
    string MBTI;

    function add (string memory _name, string memory _bio, string memory _MBTI) public{
        name = _name;
        bio = _bio;
        MBTI = _MBTI;
    } 

    function retrieve () public view returns (string memory, string memory, string memory){
        return (name, bio, MBTI);
    }
}