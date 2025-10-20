// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;    

contract SaveMyName {
    string name;  // 默认合约内部可见
    string bio;

    // 修改用户信息 需要gas
    function add(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }
    // 获取用户信息 免费
    function retrieve() public view returns (string memory, string memory) {
        return (name, bio);
    }
    // 同时修改并获取 高效但需要gas
    function saveAndRetrieve(string memory _name, string memory _bio) public returns (string memory, string memory) {
        name = _name;
        bio = _bio;
        return (name, bio);
    }
}
