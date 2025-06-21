//SPDX-License-Identifier:MTI
pragma solidity ^0.8.0;
//接口合约 定义所有保险箱必须实现的功能
interface IDepositBox{
    function getOwner() external view returns(address);
    function transferOwnership(address newOwner) external;
    function storeSecrets(string calldata secret) external;
    function getSecrets() external view returns(string memory);
    function getBoxType() external pure returns(string memory);
    function getDepositTime() external view returns(uint256);
}