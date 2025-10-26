// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// SaveMyName
contract SaveMyName{
    
    // 状态变量，值会被永久存储在区块链
    string name;
    string bio;

    // 下划线开头变量，占位符，用于存储用户输入
    function add(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }

    // 状态只读，无需gas费
    function retrieve() public view returns (string memory, string memory){
        return (name,bio);
    }

    // 存储变量，并且返回，需要gas
    function saveAndRetrieve(string memory _name, string memory _bio) public returns (string memory, string memory) {
        name = _name;
        bio = _bio;
        return (name, bio);
    }

}