// SPDX-License-Identifier:MIT
// use MIT permission

pragma solidity ^0.8.0;
// define solidity version
// notice: end with ;
//注意：每个新的sol都需要定义上面的内容，属于标准格式

//定义“用户文档”的合约
contract UserDocument {

    //如果变量是字符串，提前申明
    string name;
    string bio;
    //可以定义字符串变量是puclic/private


   //增加信息
   function add(string memory Name,string memory Bio) public {
    //add函数：增加，public定义任何人可见
    // string后面需要定义是memory（临时存储，当下使用)还是storage（永久储存)

    name = Name;
    bio = Bio;
    //变量使用小写
   //注意：不要漏：
   }

   //检索信息
   function retrieve() public view returns(string memory,string memory){
    //view查看/只读 不需要消耗gas，属于免费查询反馈
    //也要定义是public view，任何人可只读
    //returns后面定义了是字符串，临时储存的内容

    return (name,bio);
    //定义返回的变量，不要漏；
   }

}

//定义新的用户文档 合约
contract NewUserDocument{

    //申明字符串
    string name;
    string bio;

    // 同时定义函数add和retrieve，增加后就可以检索，但是检索会消耗gas
    function addAndretrieve(string memory Name, string memory Bio) public returns(string memory,string memory){
        name=Name;
        bio=Bio;
        return(name,bio);
    } 
}
