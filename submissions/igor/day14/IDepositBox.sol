// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IDepositBox{
//定义所有类型vault都有的
    function getOwner() external view returns(address);
    function transferOwnership(address _addr) external;
    function storeSecret(string calldata secret) external;
    function getSecret() external view returns(string memory);
    function getBoxType() external pure returns(string memory);
    function getDepositTime() external view returns(uint256);

}