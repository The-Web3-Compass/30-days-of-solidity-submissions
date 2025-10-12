// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract pollStation{

    string[] private  nameArray;
    mapping(string=>uint256) private countMap;

    /// 
    /*
     * @dev  初始化投票人名字到nameArray，
        初始化票数count为0
     * @param _name
     */
    function nameInit(string memory _name) public{
        nameArray.push(_name);
        countMap[_name] = 0;
    }

    function addCount(string memory _name) public {
        countMap[_name]++;
    } 

    /*  
     * @dev  获取所有投票人名字
     */
    function getNameArray() public view returns ( string[] memory){
        return nameArray;
    }

   

}