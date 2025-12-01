// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14_IDepositBox.sol";
import "./day14_BaseDepositBox.sol";
import "./day14_BasicDepositBox.sol";
import "./day14_PremiumDepositBox.sol";
import "./day14_TimeLockedDepositBox.sol";

contract VaultManager {
    // 一个人有多个box
    mapping(address=>address[]) private userDepositBoxes;
    // box地址-》名称
    mapping(address => string) private boxNames;


    /* 
        创建box
    
        new一个对象，等同于将对象合约在链上重新部署了一次，得到新的合约地址
        后边的new方法，就是对象合约中声明的构造方法
        构造方法只在合约部署时执行一次
        一个合约只有一个构造方法

        对象合约中 获取msg.sender时 拿到的是当前本合约的地址，不是用户地址
        如果需要用户地址，作为构造请求参数传入
        
    */
    function createBasicBox() public returns (address){
        BasicDepositBox newBox = new BasicDepositBox();
        userDepositBoxes[msg.sender].push(address(newBox));
        return address(newBox);
    }

    function createPremiumBox() public returns (address){
        PremiumDepositBox newBox = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(newBox));
        return address(newBox);
    }

    function createTimeLockBox(uint lockTime) public returns (address){
        TimeLockedDepositBox newBox = new TimeLockedDepositBox(lockTime);
        userDepositBoxes[msg.sender].push(address(newBox));
        return address(newBox);
    }

    //box命名
    function boxNamed(address boxAddr , string calldata name) external {
        IDepositBox box = IDepositBox(boxAddr);
        require(box.getOwner() == msg.sender , unicode"当前用户不是box拥有者");
    
        boxNames[address(box)] = name;
    }

    // box 存入数据
    function storeSecret(address boxAddr , string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddr);
        require(box.getOwner() == msg.sender , unicode"当前用户不是box拥有者");
    
        box.storeSecret(secret);
    }

    function transferBoxOwnership(address boxAddr, address newOwner) external {
        IDepositBox box = IDepositBox(boxAddr);
        require(box.getOwner() == msg.sender , unicode"当前用户不是box拥有者");

        box.transferOwnership(newOwner);

        /* 
            移除旧用户的box列表
        
            storage 获取到的是链上数据的真实引用
            改动会上链，消耗gas
            memory 获取到的是复制到临时内存中的副本引用
            不影响链上数据，gas很节省，只收一个执行费
            
            将最后一个元素挪到旧box位置
            数组的pop方法 将数组永久删除最后一个元素
        */
        address[] storage userBoxs = userDepositBoxes[msg.sender];
        for(uint i = 0 ; i<userBoxs.length ; i++){
            // 找到变更的box
            if(userBoxs[i] == boxAddr ){
                userBoxs[i] = userBoxs[userBoxs.length - 1];
                userBoxs.pop();
                break;
            }
        }
        userDepositBoxes[newOwner].push(boxAddr);
    }

    function getUserBoxs(address userAddr) external view returns (address[] memory){
        return userDepositBoxes[userAddr];
    }

    function getBoxName(address boxAddr) external view returns (string memory){
        return boxNames[boxAddr];
    }

    function getBoxInfo(address boxAddr) external view returns (
        string memory boxtype,
        uint depositTime,
        string memory name,
        address owner
    ){
        IDepositBox box = IDepositBox(boxAddr);
        return (box.getBoxType(),box.getDepositTime(),boxNames[boxAddr] , box.getOwner());
    }
}