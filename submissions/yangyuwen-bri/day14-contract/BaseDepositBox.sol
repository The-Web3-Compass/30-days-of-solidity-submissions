//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";
//抽象合约 实现保险箱的通用功能

abstract contract BaseDepositBox is IDepositBox{
    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can perform this action.");
        _;
    }

    constructor(){
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    function getOwner() public view override returns(address){
        return owner;
    }

    function transferOwnership(address newOwner) external virtual override onlyOwner{
        require(newOwner != address(0), "invalid address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function storeSecrets(string calldata _secret) external virtual override onlyOwner{
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function getSecrets() public view virtual override onlyOwner returns(string memory){
        return secret;
    }

    function getDepositTime() external view virtual override returns(uint256){
        return depositTime;
    }

}
