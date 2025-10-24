//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDepositBox {     //声明了一个 接口（interface），名字叫 IDepositBox

    function getOwner() external view returns (address);     //定义一个外部函数 getOwner()--返回盒子的当前所有者。
    function transferOwnership(address newOwner) external;     //定义一个外部函数 transferOwnership()--允许将所有权转移给其他人,接受一个新地址参数 newOwner
    function storeSecret(string calldata secret) external;     //定义一个外部函数 storeSecret()--用于将字符串（我们的“秘密”）保存在保险库中
    function getSecret() external view returns (string memory);     //定义一个外部函数 getSecret()--检索存储的秘密
    function getBoxType() external pure returns (string memory);     //定义一个外部函数 getBoxType()--让我们知道盒子的类型（基础版、高级版等）
    function getDepositTime() external view returns (uint256);     //定义一个外部函数 getDepositTime()--返回盒子的创建时间

}