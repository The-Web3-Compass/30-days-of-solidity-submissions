// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SaveMyName {
    // 状态变量：姓名、简介和活跃状态
    string name;
    string bio;
    bool isActive;

    // 保存用户档案
    function saveProfile(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
        isActive = true;
    }

    // 读取用户档案
    function getProfile() public view returns(string memory, string memory, bool){
        return(name, bio, isActive);
    }

    // 设置档案活跃状态的函数（可选，用于档案管理）
    function setActiveStatus(bool _isActive) public {
        isActive = _isActive;
    }
}