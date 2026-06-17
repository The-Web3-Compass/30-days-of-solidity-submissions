// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SaveMyName {
     string private  name;
     string private email;
     string private home_address;
     bool private is_student;
     string private bio;

    function set_profile(string calldata _yourname , string calldata _youremail , string calldata _yourhomeaddress ,bool _areyoustudent , string calldata _yourbio) public{
        name = _yourname;
        email = _youremail;
        home_address = _yourhomeaddress;   
        is_student = _areyoustudent;
        bio = _yourbio;

    }
    function get_profile()public  view returns(string memory,string memory , string memory , bool ,string memory) {
        return (name , email , home_address, is_student,bio);
    }
    

}