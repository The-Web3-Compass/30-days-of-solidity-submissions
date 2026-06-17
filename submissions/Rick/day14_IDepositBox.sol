// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    interface 只声明了接口函数，必须由继承的子合约实现
*/
interface IDepositBox {
    
    // 返回当前box 拥有者
    function getOwner() external view returns (address);
    // 将box所有权转让给其他人
    function transferOwnership(address newOwner) external;
    // 保存一个字符串到box中
    function storeSecret(string calldata secret) external;
    // 查询存储的秘密string
    function getSecret() external view returns (string memory);
    // 查询box类型
    function getBoxType() external pure returns (string memory);
    // 查询box创建时间
    function getDepositTime() external view returns (uint256);
}