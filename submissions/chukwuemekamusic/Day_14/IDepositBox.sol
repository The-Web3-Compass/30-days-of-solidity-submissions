// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDepositBox {
    function storeSecret(string calldata secret) external;
    function updateSecret(string calldata secret) external;
    function transferOwnership(address newOwner) external;
    function getSecret() external view returns (string memory);
    function getBoxType() external view returns(string memory); // pure
    function getDepositTime() external view returns(uint256);
    function getOwner() external view returns (address Owner);
    function isOwner(address account) external view returns (bool);

}