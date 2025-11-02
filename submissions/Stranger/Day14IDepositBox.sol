// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositBox {
    function getOwner() external view returns (address); // returns用于函数声明中, return用于函数体内
    function transferOwnership(address newOwner) external;
    function storeSecret(string calldata secret) external; // 变量定义时的数据位置关键字有: memory(临时), storage(永久), calldata(临时且只读)
    function getSecret() external view returns (string memory);
    function getBoxType() external pure returns (string memory);
    function getDepositTime() external view returns (uint256);
}