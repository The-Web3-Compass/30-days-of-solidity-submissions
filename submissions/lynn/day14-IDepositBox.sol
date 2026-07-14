//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositBox {
    function getOwner() external view returns(address);
    function transferOwner(address _newOwner) external;
    function storeSecret(string calldata _secrete) external;
    function getSecret() external view returns(string memory);
    function getBoxType() external pure returns(string memory);
    function getBoxCreatedTime() external view returns(uint256);
}