// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14IDepositBox.sol";
import "./Day14BasicDepositBox.sol";
import "./Day14PremiumDepositBox.sol";
import "./Day14TimeLockedDepositBox.sol";

contract VaultManager {
    // 用户存款箱  及 存款箱名映射
    mapping(address => address[]) private userDepositBoxes;
    mapping(address => string) private boxNames;

    // 存款箱创建事件 及 存款箱命名事件
    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType); // 将用户的地址映射到其拥有的所有存款箱地址
    event BoxNamed(address indexed boxAddress, string name); // 将存款箱地址映射到名字

    // 创建 BasicBox
    function createBasicBox() external returns (address) {
        BasicDepositBox box = new BasicDepositBox(); // 部署一个新的 BasicDepositBox 合约并将其地址存储在变量 box 中
        userDepositBoxes[msg.sender].push(address(box)); // 将新创建的存款箱地址添加到用户的存款箱列表中
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    // 创建 PremiumBox
    function createPremiumBox() external returns (address) {
        PremiumDepositBox box = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    // 创建 TimeLockedBox
    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }

    // 为存款箱命名
    function nameBox(address boxAddress, string calldata name) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);
    }

    // 存储秘密
    function storeSecret(address boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.storeSecret(secret);
    }

    // 转移存款箱属主
    function transferBoxOwnership(address boxAddress, address newOwner) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.transferOwnership(newOwner);
        address[] storage boxes = userDepositBoxes[msg.sender];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }
        // 添加新的存款箱属主关系
        userDepositBoxes[newOwner].push(boxAddress);
    }

    // 获取用户的存款箱列表
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }

    // 获取存款箱名字
    function getBoxName(address boxAddress) external view returns (string memory) {
        return boxNames[boxAddress];
    }

    // 获取存款箱信息
    function getBoxInfo(address boxAddress) external view returns (string memory boxType, address owner, uint256 depositTime, string memory name) {
        IDepositBox box = IDepositBox(boxAddress);
        return (box.getBoxType(), box.getOwner(), box.getDepositTime(), boxNames[boxAddress]);
    }
}