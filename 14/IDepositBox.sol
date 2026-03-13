// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositBox {

    function storeSecret(string calldata _secret) external;

    function readSecret() external view returns(string memory);

    function transferOwnership(address newOwner) external;

    function owner() external view returns(address);
}