// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 
import "./IDepositBox.sol";

// 基础型抽象合约
// ！！！关键字abstract 表示这个合约不能直接部署，只是其他合约构建的模板或地基
abstract contract BaseDepositBox is IDepositBox {

    // 状态变量——private，表示它们只能在内部访问。如果有人想读取它们，必须通过我们提供的公共getter 函数来查
    address private owner;
    string private secret;
    uint256 private depositTime;

    // 事件：转移存储箱所有权；存储新秘密
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    // 构造函数：金库在创建时自动设置所有权和记录创建时间。
    constructor(){
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Not the owner");
        _;
    }

    // 返回金库档案所有者
    // override 重写母合约函数
    function getOwner() public view override returns (address){
        return owner;
    }

    // 转移所有权
    // virtual针对子合约（允许未来的子合约继续重写）；override针对母合约的（实现/重写接口或母合约的函数）
    function transferOwnership(address newOwner) external virtual override onlyOwner{
        require(newOwner != address(0), "Invalid Address");
        emit OwnershipTransferred(owner, newOwner); 
        owner = newOwner;
    }

    // 存储秘密
    // calldata 传递字符串参数，在gas上更便宜
    function storeSecret(string calldata _secret)external virtual override onlyOwner{
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    // 检索存储秘密
    function getSecret() public view virtual override onlyOwner returns (string memory){
        return secret;
    }

    // 返回金库部署的时间
    function getDepositTime() external view virtual override onlyOwner returns (uint256) {
        return depositTime;
    }

    
   
    
    

}
