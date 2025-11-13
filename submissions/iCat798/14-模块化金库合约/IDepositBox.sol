//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

interface IDepositBox {

    // 返回存款箱的当前所有者
    function getOwner() external view returns(address);

    // 允许将所有权转移给其他人
    function transferOwnership(address newOwner)external;

    // 一个用于将字符串（我们的“秘密”）保存在金库中的函数
    function storeSecret(string calldata secret)external;

    // 检索存储的秘密
    function getSecret() external view returns (string memory);

    // 获知存款箱类型（基础型、高级型等）
    function getBoxType() external pure returns(string memory);
    
    // 获知存款箱的创建时间
    function getDepositTime() external view returns(uint256);
}