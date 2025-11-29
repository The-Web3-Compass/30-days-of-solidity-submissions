// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14-IDepositBox.sol";
import "./Day14-BasicDepositBox.sol";
import "./Day14-PremiumDepositBox.sol";
import "./Day14-TimeLockedDepositBox.sol";//导入合约

contract VaultManager {
    mapping(address => address[]) private userDepositBoxes;//用户地址对应box地址的列表，一个人可能多个box地址
    mapping(address => string) private boxNames;//box地址对应box名字

    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);//box创建（owner，box地址，box类型
    event BoxNamed(address indexed boxAddress, string name);//box命名 box地址 名字

    function createBasicBox() external returns (address) {//创建基础box
        BasicDepositBox box = new BasicDepositBox(msg.sender,address(this));//"拥有/管理" (Has-A)：合约 A 拥有/管理合约 B 的独立实例。1对多调用
        userDepositBoxes[msg.sender].push(address(box));//用户box地址加入到box地址列表里
        emit BoxCreated(msg.sender, address(box), "Basic");//广播：新box建成了
        return address(box);//返回box地址
    }

    function createPremiumBox() external returns (address) {//创建prmiumbox
        PremiumDepositBox box = new PremiumDepositBox(msg.sender,address(this));
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    function createTimeLockedBox(uint256 lockDuration) external returns (address) {//创建TimeLockedBox，注意TimeLockedDepositBox里有合约构造函数定义uint256 lockDuration，所以这里也需要定义
        TimeLockedDepositBox box = new TimeLockedDepositBox(msg.sender,lockDuration,address(this));
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }

    function nameBox(address boxAddress, string calldata name) external {
        IDepositBox box = IDepositBox(boxAddress);//我知道这个 boxAddress 上部署了一个合约。请你相信我，这个合约实现了 IDepositBox 接口中定义的所有功能。将结果赋值给 box
        require(box.getOwner() == msg.sender, "Not the box owner");

        boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);
    }

    function storeSecret(address boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        //box.storeSecret(secret);
        box.storeSecretByManager(msg.sender, secret);
    }

    function transferBoxOwnership(address boxAddress, address newOwner) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        //box.transferOwnership(newOwner);
        box.transferOwnershipByManager(newOwner);

        address[] storage boxes = userDepositBoxes[msg.sender];//找到要特换的地址，然后从box列表里删除
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }

        userDepositBoxes[newOwner].push(boxAddress);//把box地址添加到新的owner手里
    }

    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }

    function getBoxName(address boxAddress) external view returns (string memory) {
        return boxNames[boxAddress];
    }

    function getBoxInfo(address boxAddress) external view returns (//获取box信息
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
