// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract SaveMyName {
    string name;
    string bio;

    // 添加名字和简介
    function add(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }

    // 读取当前存储的名字和简介
    function retrieve() public view returns (string memory, string memory) {
        return (name, bio);
    }

    // 同时保存并返回名字和简介
    function saveAndRetrieve(string memory _name, string memory _bio) public returns (string memory, string memory) {
        name = _name;
        bio = _bio;
        return (name, bio);
    }
}
