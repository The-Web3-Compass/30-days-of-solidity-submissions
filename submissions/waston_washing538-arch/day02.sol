// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
  contract Save_My_Name{
string name;  // 全局作用域
string bio;
function add ( string memory  _name,string memory _bio) public {
    name=_name;    //状态变量    add 是能让我输入的
    bio=_bio;
}
    

function retrieve() public view returns (string memory , string memory){
    return (name,bio);          //view 只读 
}
  }

  /*
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
function saveAndRetrieve(string memory _name, string memory _bio) public returns (string memory, string memory) {
    name = _name;
    bio = _bio;
    return (name, bio);
}
*/
/*
    // 函数：获取用户信息（返回姓名、简介、年龄、职业）
    function getUserInfo() public view returns (
        string memory,
        string memory,
        uint256,
        string memory
    ) {
        return (name, bio, age, profession);
    }
}
*/