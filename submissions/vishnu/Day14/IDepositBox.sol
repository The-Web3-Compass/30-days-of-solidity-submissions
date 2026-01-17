// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositBox {

    enum BoxStatus { Active, Locked, Expired, Closed }

    event Deposit(address indexed depositor, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed owner, uint256 amount, uint256 timestamp);
    event SecretStored(address indexed owner, string secretHash);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BoxStatusChanged(BoxStatus previousStatus, BoxStatus newStatus);
    
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function storeSecret(string memory secretHash) external;
    function getSecret() external view returns (string memory);
    
    function transferOwnership(address newOwner) external;
    function owner() external view returns (address);
    
    function getBoxInfo() external view returns (
        string memory boxType,
        BoxStatus status,
        uint256 balance,
        address currentOwner,
        uint256 creationTime
    );

    function getStatus() external view returns (BoxStatus);
    function canWithdraw() external view returns (bool);
    function canDeposit() external view returns (bool);
}
