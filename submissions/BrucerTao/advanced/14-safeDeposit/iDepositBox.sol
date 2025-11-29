// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositBox {
    function getOwner() external view returns (address); //返回盒子的当前所有者
    function transferOwnerShip(address newOwner) external; //允许将所有权转让给其他人
    function storeSecret(string calldata secret) external; //保存在库中
    function getSecret() external view returns (string memory); //检索存储的密钥
    function getBoxType() external pure returns (string memory); //获取什么类型的盒子
    function getDepositTime() external view returns (uint256); //返回创建框的时间

}