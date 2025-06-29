//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SaveMyName{

    string name;
    string bio;
    string mbti;

    function add(string memory _name,string memory _bio,string memory _mbti) public {
        name=_name;
        bio=_bio;
        mbti=_mbti;
    }

    function retrieve() public view returns(string memory,string memory ,string memory) {
        return (name,bio,mbti);
    }
}
