// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVault{
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}