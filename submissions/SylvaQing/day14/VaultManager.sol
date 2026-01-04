// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

//金库仪表板:供用户创建、命名、管理和与他们的存款箱交互
import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

contract VaultManager {
    //用户的地址映射
    // 拥有的所有存款箱
    mapping (address=>address[])private userDepositBoxes;
    //存款箱名字
    mapping (address=>string)private depositBoxNames;


    event BoxCreated(address indexed owner,address indexed boxAddress,string boxType);
    event BoxNamed(address indexed boxAddress,string boxName);
/*=========创建==========*/
    //创建基础存款箱
    function createBasicBox() external returns (address){
        BasicDepositBox basicBox = new BasicDepositBox();
        userDepositBoxes[msg.sender].push(address(basicBox));
        emit BoxCreated(msg.sender,address(basicBox),"Basic");
        return address(basicBox);
    }
    //创建高级存款箱
    function createPremiumBox() external returns (address){
        PremiumDepositBox premiumBox = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(premiumBox));
        emit BoxCreated(msg.sender,address(premiumBox),"Premium");
        return address(premiumBox);
    }
    //创建时间锁定金库
    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }
/*=========实际操作==========*/
    //命名
    function nameBox(address boxAddress, string calldata name) external {
        //通用地址转换为接口，可以在存款箱上调用 getOwner()
        IDepositBox box = IDepositBox(boxAddress);
        // 检查所有权
        require(box.getOwner() == msg.sender, "Not the box owner");
        // 事件触发
        depositBoxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);
    }
    //存储
    function storeSecret(address boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        box.storeSecret(secret);
    }
    //移交存款箱
    function transferBoxOwnership(address boxAddress, address newOwner) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        box.transferOwnership(newOwner); //这个是接口里的

        // 旧-
        address[] storage boxes = userDepositBoxes[msg.sender];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }
        // 新+
        userDepositBoxes[newOwner].push(boxAddress);

    }

/*=========查看==========*/
    // 所有存储箱
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }
    // 存款箱的自定义名称
    function getBoxName(address boxAddress) external view returns (string memory) {
        return depositBoxNames[boxAddress];
    }
    // 一次调用获取完整信息
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
            depositBoxNames[boxAddress]
        );
    }
    





}