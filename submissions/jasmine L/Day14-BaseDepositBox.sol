// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14-IDepositBox.sol";//引入接口文件

abstract contract BaseDepositBox is IDepositBox{
    address private owner;
    uint256 private depositTime;
    string private secret;

    event ownershipTransferred(address indexed owner, address indexed  newOwner);// 权限转移
    event secretStored(address indexed owner);//宝物已存好


    constructor(){
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Not owner");
        _;
    }

    function getOwner() public view override returns(address){//到此为止，之后的子合约不会被重写
        return owner;
    }

    function transferOwnership(address newOwner) external virtual override onlyOwner{
        require(newOwner != address(0),"Invaild address 0");
        emit ownershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner{
        secret = _secret;
        emit secretStored(msg.sender);
    }
    function getSecret() public virtual override view onlyOwner returns (string memory){
        return secret;
    }

    function getDepositTime() external view virtual override onlyOwner returns (uint256){
        return depositTime;
    }
    
}
