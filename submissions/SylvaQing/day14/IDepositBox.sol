// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

//接口
interface IDepositBox {
    function getOwner() external view returns (address); //存款箱的当前所有者。
    function transferOwnership(address newOwner)external ; //允许将所有权转移给其他人
    function storeSecret(string calldata secret) external;//将字符串保存在金库
    function getSecret() external view returns (string memory);//检索
    function getBoxType() external pure returns (string memory);//存款箱类别
    function getDepositTime() external view returns (uint256);//创建时间
}