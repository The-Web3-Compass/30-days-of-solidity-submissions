// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositBox {
    function getOwner()external view returns (address); // 获取保险箱地址
    function transferOwnership(address newOwner) external; // 转移保险箱所有权
    function storeSecret(string calldata secret) external; // 存储加密字符串到保险箱
    function getSecret() external view returns(string memory); // 获取保险箱加密字符串
    function getBoxType() external pure returns(string memory); // 获取保险箱类型
    function getDepositTime()external view returns(uint256); // 获取保险箱创建时间
}