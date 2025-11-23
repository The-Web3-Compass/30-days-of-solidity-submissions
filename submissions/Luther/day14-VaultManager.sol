//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day14-IDepositBox.sol";
import "./day14-BasicDepositBox.sol";
import "./day14-PremiumDepositBox.sol";
import "./day14-TimeLockedDepositBox.sol";

contract VaultManager {     //定义主合约 VaultManager，用于管理所有用户的存款盒。
    mapping(address => address[]) private userDepositBoxes;     //userDepositBoxes：记录每个用户（address）创建的所有盒子地址列表（address[]）
    mapping(address => string) private boxNames;     //boxNames：记录每个盒子的自定义名称

    //定义两个事件，用于记录操作日志
    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);      
    //BoxCreated：当用户创建新盒子时触发，包含：1.创建者地址 owner 2.新盒子合约地址 boxAddress 3.盒子类型 "Basic", "Premium", 或 "TimeLocked"

    event BoxNamed(address indexed boxAddress, string name);     //BoxNamed：当盒子被命名或重命名时触发

    //让用户创建一个 基础版存款盒（BasicDepositBox）,每个用户可以通过此函数创建属于自己的独立合约实例
    function createBasicBox() external returns (address) {
        BasicDepositBox box = new BasicDepositBox();     //部署一个新的 BasicDepositBox 合约实例
        userDepositBoxes[msg.sender].push(address(box));     //把新盒子的地址存入调用者的盒子列表中
        emit BoxCreated(msg.sender, address(box), "Basic");     //触发 BoxCreated 事件，记录操作日志
        return address(box);     //返回新盒子的地址
    }

    //创建一个 高级版存款盒（PremiumDepositBox）,逻辑与上一个类似，只是类型不同
    function createPremiumBox() external returns (address) {
        PremiumDepositBox box = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    //创建一个 时间锁版存款盒（TimeLockedDepositBox）
    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);     //参数 lockDuration：锁定时间（单位秒），由用户传入
        userDepositBoxes[msg.sender].push(address(box));     //在合约构造时传入到 TimeLockedDepositBox 构造函数中
        emit BoxCreated(msg.sender, address(box), "TimeLocked");     //创建后记录到该用户名下
        return address(box);
    }

    //允许盒子所有者为自己的盒子设置名称
    function nameBox(address boxAddress, string calldata name) external {     //将目标地址强制转换为 IDepositBox 接口
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");     //调用 getOwner() 检查调用者是否为盒子的拥有者

        boxNames[boxAddress] = name;     //将名称存入 boxNames 映射
        emit BoxNamed(boxAddress, name);     //触发事件 BoxNamed
    }

    //让盒子所有者通过管理器调用其盒子的 storeSecret() 函数，存入秘密
    function storeSecret(address boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        box.storeSecret(secret);
    }

    //检查调用者是否为该盒子当前所有者
    function transferBoxOwnership(address boxAddress, address newOwner) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        box.transferOwnership(newOwner);

        //更新管理器内部的盒子归属记录
        address[] storage boxes = userDepositBoxes[msg.sender];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }

        userDepositBoxes[newOwner].push(boxAddress);
    }

    //返回指定用户名下的所有盒子地址数组
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }

    //返回某个盒子的自定义名称（若未命名则为空字符串）
    function getBoxName(address boxAddress) external view returns (string memory) {
        return boxNames[boxAddress];
    }

    //汇总查询某个盒子的详细信息
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