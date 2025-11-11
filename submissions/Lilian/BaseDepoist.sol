// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepoistBox.sol";

abstract contract BaseDepoistBox is IDepoistBox{
    address private owner;//只有此人允许存储
    string private secret;//用户可以安全地存储私有字符串
    uint256 private depoistTime;//记录存款箱部署的准确时间

    event Ownershiptransferred(address indexed previousOwner,address indexed newOwner);//有人转移存款箱时触发
    event SecretStored (address indexed owner);//当存储新秘密时触发

    modifier onlyowner(){
        require(msg.sender == owner,"Not the box owner");
        _;//只有使用者可以运行
    }

    constructor(){
        owner = msg.sender;//部署合约的人成为owner
        depoistTime = block.timestamp;//当前时间被记录
    }

    function getOwner()public view override returns (address){
        return owner;//接口要求的返回owner函数
    }

    function transferOwnership (address newOwner)external virtual override onlyowner{
        require(newOwner !=address(0),"New owner cannot be zero address");//检查不是0地址
        emit Ownershiptransferred(owner, newOwner);//触发事件所有权变更
        owner = newOwner;
    }

    function storeSecret (string calldata _secret)external virtual override onlyowner{
        secret=_secret;//将私密字符串存储在变量中
        emit SecretStored(msg.sender);//存储后触发一个事件
    }

    function getsecret() public view virtual override onlyowner returns (string memory){
        return secret;//允许所有者来检索
    }

    function getDepoistTime () external view virtual override returns (uint256){
        return depoistTime;//返回金库部署的时间
    }

}