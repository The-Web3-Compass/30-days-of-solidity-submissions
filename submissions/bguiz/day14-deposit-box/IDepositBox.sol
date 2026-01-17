// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

interface IDepositBox {
    function saveSecret(string memory secret) external;
    function readSecret() external view returns(string memory);
    function getType() external pure returns(string memory);
    function createTime() external view returns(uint256);
}
