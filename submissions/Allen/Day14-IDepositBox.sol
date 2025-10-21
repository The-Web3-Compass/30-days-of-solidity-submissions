// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

interface IDepositBox{
     
    function getOwner() external view returns(address);

    function transferOwnership(address newOwner) external;

    // calldata: it's cheaper on gas when passing in string arguments.
    // external: it be called from outside the contract.this.func() is wrong.
    function storeSecret(string calldata secret) external;

    function getSecret() external view returns (string memory);

    function getBoxType() external pure returns (string memory);

    function getDepositTime() external view returns(uint256);



}