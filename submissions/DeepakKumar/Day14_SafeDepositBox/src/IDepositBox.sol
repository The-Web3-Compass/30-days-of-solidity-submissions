// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDepositBox {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function getBalance() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function owner() external view returns (address);
}
