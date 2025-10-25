// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPlugin {
    function execute(bytes calldata data) external;
}
