// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox{
    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    constructor(address _owner){
        owner = _owner;
        depositTime = block.timestamp;
    }

    //跨合约调用导致msg.sender不是用户钱包地址合约，不再在此处进行权限管理，在顶层进行权限管理
    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Not the box owner");
    //     _;
    // }
    function getOwner() override external view returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external virtual override {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function storeSecret(string calldata _secret) external virtual override {
        secret = _secret;
        emit SecretStored(msg.sender);
    }
    function getSecret() public view virtual override returns (string memory){
        return secret;
    }
    function getDepositTime() external view virtual override returns (uint256){
        return depositTime;
    }
}