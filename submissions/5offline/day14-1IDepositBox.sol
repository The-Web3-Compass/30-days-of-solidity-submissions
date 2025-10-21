// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositBox {
    //interface 就是一个 纯粹的函数声明集合 ——它只告诉你「某些函数存在，长什么样」，
    //合同框架 ，	不能有状态变量（就是不能声明 uint public x; 这种东西）所有函数都要是 external
    function getOwner() external view returns (address);
    function transferOwnership(address newOwner) external;
    //有关于owner的内容
    function storeSecret(string calldata secret) external;
    //calldata 是Solidity里的一种数据位置修饰符，表示这个字符串参数只读、只在函数调用期间存在，节省gas。
    function getSecret() external view returns (string memory);
    //有关于secret的内容
    function getBoxType() external pure returns (string memory);
    //不同的box，pure没有读取任何合约的状态变量
    function getDepositTime() external view returns (uint256);
    //返回 box 的创建时间。
}

