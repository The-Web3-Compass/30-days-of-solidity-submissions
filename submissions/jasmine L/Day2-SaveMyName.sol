// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// 保存名字和个人简介
contract SaveMyName {
    //定义状态变量：姓名与简介
    string name;
    string info;

    // 存储用户姓名与简介
    function add(string memory _name, string memory _info) public {
        name = _name;
        info = _info;
    }

    // 读取并返回存储的名称和简介
    function retrieve() public view returns (string memory, string memory){
        return (name, info);
    }

    // 合并两个函数的内容
    function saveAndRetrieve(string memory _name, string memory _info) public returns(string memory,string memory){
        name = _name;
        info = _info;
        return (name,info);
    } 


}
