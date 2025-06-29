// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@title 用户资料存储合约
///@author yuheng
///@notice 此合约允许用户存储和读取一个名字与简介
/*
@dev 通过存储文本数据 （用户的姓名和个人简介 ），
探索 Solidity 中的字符串、内存存储、函数返回类型和
 view 关键字
*/

contract SaveMyName {

    string name;    //声明state 变量:用户名（私有字符串）
    string bio;     //声明状态变量:用户简介（私有字符串）

    /*
    @notice 设置文本（比如，用户名和简介）的函数
    @dev 存储两个字符串变量在合约中
    @param _name 要保存的用户名称
    @param _bio 要保存的个人简介
    */
    // add() 函数 用来存储数据
    function add(string memory _name, string memory _bio) public {
        name = _name;       // 将输入的 _name 存入状态变量 name
        bio = _bio;     // 将输入的 _bio 存入状态变量 bio
    }
    /*
    @notice 获取当前存储的文本的函数（比如，获取当前存储的名称和简介）
    @dev 这是一个 view 函数，不花费 gas
    @return 返回值说明，当前存储的文本 （比如，name 和 bio）
    */
    function retrieve() public view returns (string memory, string memory){
        return (name, bio);     //返回两个字符串变量
    }

}