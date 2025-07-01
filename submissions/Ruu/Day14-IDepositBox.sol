//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IDepositBox {

    function GetOwner() external view returns(address);
    function TransferOwnership(address NewOwner) external;
    function StoreSecret(string calldata secret) external;
    function GetSecret() external view returns(string memory);
    function GetBoxType() external pure returns(string memory);
    function GetDepositTime() external view returns(uint256);
    
}
