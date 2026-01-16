// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {

    string private name;
    string private bio;
    uint256 private age;
    string private occupation;

    // 添加姓名、简介、年龄和职业
    function add(
        string memory _name,
        string memory _bio,
        uint256 _age,
        string memory _occupation
    ) public {
        name = _name;
        bio = _bio;
        age = _age;
        occupation = _occupation;
    }

    // 读取所有信息
    function retrieve()
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            string memory
        )
    {
        return (name, bio, age, occupation);
    }
}