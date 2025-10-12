
/*
 * @title 保存我的名字 - SaveMyName
 * @notice 一个简单的智能合约，用于在区块链上永久保存你的名字
 * @author George
 */

// 💡 想象这个场景：
// 在区块链上创建你的数字身份档案，存储姓名和个人简介，永久保存且可随时验证！这就是我们要构建的 ✨
// 下面是我们的实现思路：
// 1. 声明姓名(string)和简介(string)变量
// 2. 创建 saveProfile() 函数保存数据
// 3. 创建 getProfile() 函数读取数据
// 4. 添加活跃状态(bool)进行档案管理

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
  string public name;
  string public bio;
  bool public isActive;

  function saveProfile(string memory _name, string memory _bio, bool _isActive) public {
    // memory只在function中存在，是暂时性的，可以减少gas的使用，降低成本
    name = _name;
    bio = _bio;
    isActive = _isActive;
  }

  function getProfile() public view returns (string memory, string memory, bool) {
    // view表示这个函数不会对区块链产生影响，只是查看，类似于API中的get
    // returns表示这个函数会返回一个值，类似于API中的get
    return (name, bio, isActive);
  }
}
