// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
contract SaveMyName{
    string name;
    string bio;
//状态变量
function add(string memory _name, string memory _bio) public {
    name = _name;
    bio = _bio;//函数参数
}
//临时存储
function retrieve() public view returns (string memory, string memory){
    return (name, bio);
}
}