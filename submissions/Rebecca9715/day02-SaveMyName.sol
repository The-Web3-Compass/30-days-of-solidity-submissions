// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserProfile {
    // 永久保存在blockchain上的内容，会在部署的部分自动能够view
    string name;
    string bio;

    // memory只在function中存在，是暂时性的，可以减少gas的使用，降低成本
    // 其中function的input中的下划线只是一种区分方式，也可以使用其他写法如newName、newBio
    function add (string memory _name, string memory _bio) public{
        name = _name;
        bio = _bio;
    }

    // 检索用户信息的函数，view表示这个函数不会对区块链产生影响，只是查看，类似于API中的get
    function retrieve() public view returns (string memory, string memory) {
        return (name, bio);
    }
}