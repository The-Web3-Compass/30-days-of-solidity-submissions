// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

interface IDepositBox{

    function getOwner() external view returns(address);
    function transferOwnership(address _newOwner) external ;
    function storeSecret(string calldata _secret) external ;
    function getSecret()external view returns(string memory);
    function getBoxType()external view returns(string memory);
    function getDepositTime()external view returns(uint);
}