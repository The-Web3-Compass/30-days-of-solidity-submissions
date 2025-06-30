// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title 用户信息管理合约（限制用户名重复）
contract UserProfile {
    // 每个地址对应一个用户名
    mapping(address => string) private names;
    // 每个地址对应一个简介
    mapping(address => string) private bios;
    // 每个用户名映射到地址
    mapping(string => address) private nameToAddress;
    // 用户名列表
    string[] private allNames;

    event NameChanged(address indexed user, string oldName, string newName);
    event BioChanged(address indexed user, string oldBio, string newBio);

    /// @notice 设置用户名（限制重名）
    function setName(string memory _name) public {
        string memory oldName = names[msg.sender];
        address existingUser = nameToAddress[_name];

        // 用户名不能被其他人使用
        if (existingUser != address(0) && existingUser != msg.sender) {
            revert("This name is already taken.");
        }

        // 如果是改名，移除旧映射
        if (bytes(oldName).length > 0) {
            delete nameToAddress[oldName];
        } else {
            // 首次设置，加到用户列表
            allNames.push(_name);
        }

        // 保存新用户名
        names[msg.sender] = _name;
        nameToAddress[_name] = msg.sender;

        emit NameChanged(msg.sender, oldName, _name);
    }

    /// @notice 设置个人简介
    function setBio(string memory _bio) public {
        string memory oldBio = bios[msg.sender];
        bios[msg.sender] = _bio;
        emit BioChanged(msg.sender, oldBio, _bio);
    }

    /// @notice 获取自己设置的用户名
    function getMyName() public view returns (string memory) {
        return names[msg.sender];
    }

    /// @notice 获取自己设置的简介
    function getMyBio() public view returns (string memory) {
        return bios[msg.sender];
    }

    /// @notice 根据用户名获取该用户的简介
    function getBioByName(string memory _name) public view returns (string memory) {
        address userAddr = nameToAddress[_name];
        require(userAddr != address(0), "Name not found");
        return bios[userAddr];
    }

    /// @notice 获取所有注册用户名
    function getAllNames() public view returns (string[] memory) {
        return allNames;
    }
}
