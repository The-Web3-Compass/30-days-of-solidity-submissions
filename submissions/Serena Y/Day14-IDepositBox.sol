// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IDepositBox {
    function getOwner() external view returns (address);//返回存款箱的当前所有者
    function transferOwnership(address newOwner) external;// 允许将所有权转移给其他人
    function storeSecret(string calldata secret) external;//一个用于将字符串（我们的“秘密”）保存在金库中的函数
    function getSecret() external view returns (string memory);// 检索存储的秘密
    function getBoxType() external pure returns (string memory);//让我们知道它是哪种类型的存款箱（基础型、高级型等）
    function getDepositTime() external view returns (uint256);//返回存款箱的创建时间
    function transferOwnershipByManager(address newOwner) external;
    function storeSecretByManager(address ownerAddress, string calldata _secret) external;
}
