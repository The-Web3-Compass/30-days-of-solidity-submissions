// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

contract VaultManager {
    // 每个用户地址 => 其所有的存储盒子地址
    mapping(address => address[]) private userDepositBoxes;

    // 每个盒子地址 => 自定义名称
    mapping(address => string) private boxNames;

    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event BoxNamed(address indexed boxAddress, string name);

    // 创建 Basic 类型盒子
    function createBasicBox() external returns (address) {
        BasicDepositBox box = new BasicDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    // 创建 Premium 类型盒子
    function createPremiumBox() external returns (address) {
        PremiumDepositBox box = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    // 创建 TimeLocked 类型盒子
    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }

    // 为盒子命名
    function nameBox(address boxAddress, string memory name) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);
    }

    // 存储机密
    function storeSecret(address boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.storeSecret(secret);
    }

    // 转移盒子的所有权（并更新管理记录）
    function transferBoxOwnership(address boxAddress, address newOwner) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        require(newOwner != address(0), "Invalid new owner");

        // 转移合约内部所有权
        box.transferOwnership(newOwner);

        // 从旧用户列表中移除盒子
        address[] storage boxes = userDepositBoxes[msg.sender];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == boxAddress) {
                boxes[i] = boxes[boxes.length - 1]; // 将最后一个移到当前位置
                boxes.pop();
                break;
            }
        }

        // 添加到新用户名下
        userDepositBoxes[newOwner].push(boxAddress);
    }

    // 查询用户所有盒子
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }

    // 获取盒子的自定义名称
    function getBoxName(address boxAddress) external view returns (string memory) {
        return boxNames[boxAddress];
    }

    // 获取完整盒子信息
    function getBoxInfo(address boxAddress) external view returns (
        string memory boxType,
        address owner,
        uint256 depositTime,
        string memory name
    ) {
        IDepositBox box = IDepositBox(boxAddress);
        return (
            box.getBoxType(),
            box.getOwner(),
            box.getDepositTime(),
            boxNames[boxAddress]
        );
    }
}