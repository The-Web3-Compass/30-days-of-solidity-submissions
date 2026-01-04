// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SaveMyName{
    /*该方式是infinite gas*/
    // string name ;
    // string bio ;
    // function saveAndRetrieve(string memory _name,string memory _bio) 
    // public  returns(string memory,string memory){
    //     name= _name;
    //     bio= _bio;
    //     return (name, bio);
    //     
    // }

    string public name;
    string public bio;

    // 写入函数（消耗 gas）
    function save(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }

    // 读取函数（不消耗 gas）
    function get() public view returns (string memory, string memory) {
        return (name, bio);
    }
}