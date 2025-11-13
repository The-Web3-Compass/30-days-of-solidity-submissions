// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

// 金库控制中心（后端）：
contract VaultManager{

    // 将用户的地址映射到其拥有的所有存款箱（作为合约地址）
    mapping(address => address[]) private userDepositBoxes;

    // 允许用户为每个邮箱分配自定义名称。按邮箱地址存储。
    mapping(address => string)private boxNames;

    // 创建新存款箱
    event BoxCreated(address indexed owner, address indexed boxAdress, string boxType);

    // 自定义存款箱名称
    event BoxNamed(address indexed boxAdress, string name);

    // 创建基础存款箱
    function createBasicBox() external returns (address){

        // ？？？部署一个新的 BasicDepositBox 合约并将其地址存储在变量 box 中。
        BasicDepositBox box = new BasicDepositBox();

        // 将新存款箱添加到发送者拥有的存款箱列表中
        userDepositBoxes[msg.sender].push(address(box));

        // 触发一个事件，以便 UI 可以跟踪此创建
        emit BoxCreated(msg.sender, address(box), "Basic");

        // 返回新存款箱的地址以便于访问
        return address(box);
    }

    // 创建高级存款箱：适用于想要存储额外元数据的用户
    function createPremiumBox() external returns (address){

        // 创建了一个全新的合约 PremiumDepositBox,后台：
        // - 继承自 BaseDepositBox，从而获得获得所有权、秘密存储、存入时间等信息
        // - 添加一个名为 metadata 的新状态变量以便更新/检索。
        PremiumDepositBox box = new PremiumDepositBox();

        // 将存款箱保存在用户的存款箱列表中
        userDepositBoxes[msg.sender].push(address(box));

        // 为前端和跟踪触发事件
        emit BoxCreated(msg.sender, address(box), "Premium");

        // 返回存款箱地址
        return address(box);
    }


    // 创建时间锁存款箱（需传入参数lockDuration）
    function createTimeLockedBox(uint256 lockDuration) external returns (address){

        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);

        // 将存款箱保存在用户账户下
        userDepositBoxes[msg.sender].push(address(box));

        // 触发 BoxCreated 事件
        emit BoxCreated(msg.sender, address(box), "Time Locked");

        // 回新部署合约的地址，以便调用者（或前端）可以立即开始与其交互
        return address(box);
    }

    function nameBox(address boxAddress, string memory name ) external{

        // ？？？将通用地址转换为接口
        IDepositBox box = IDepositBox(boxAddress);

        // 检查所有权
        require(box.getOwner() == msg.sender, "Not the box owner");
        boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);

    }

    // 调用接口中的 storeSecret() 函数
    function storeSecret(address boxAddress, string calldata secret) external{
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        // ？？？没有触发事件，因为存款箱本身会触发一个（SecretStored）
        box.storeSecret(secret);
    }

    // 转移存款箱所有权
    function transferBoxOwnership(address boxAddress, address newOwner)  external{
        
        // 接口转换和所有权检查
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        // ？？？调用存款箱 transferOwnership()：真正的数据所有权和业务逻辑归属于存储箱合约—VaultManager 不是其所有者—因此，这一步确保了权限变更在存储箱内部自主完成。
        box.transferOwnership(newOwner);

        // 更新 VaultManager 的映射
        address[] storage boxes = userDepositBoxes[msg.sender];

        // ？？？从发送者列表中移除存储箱：循环查找正在被转移的那个存款箱
        for(uint i = 0; i < boxes.length; i++){

            // 找到后将它与数组中的最后一项交换
            boxes[i] = boxes[boxes.length - 1];

            // 删除最后一项
            boxes.pop();

            break;
        }

        // 将存储箱添加到新所有者的列表
        userDepositBoxes[newOwner].push(boxAddress);
      
    }
    
    // 查看指定用户拥有的所有存储箱
    // 使用场景：非常适合创建列出用户存款箱的仪表板或个人资料页面。
    function getUserBoxes(address user) external view returns(address[] memory){
        return userDepositBoxes[user];
    }

    // 读取存款箱的自定义名称
    // 使用场景：对于改进 UI 非常有用——你可以显示有意义的名称，如“主金库”或“爸爸的储物柜”，而不是显示原始地址。
    function getBoxName(address boxAddress) external view returns (string memory) {
    return boxNames[boxAddress];
    }

    // ！！！一体化辅助函数:一次调用获取完整信息
    function getBoxInfo(address boxAddress)external view returns(
        string memory boxType,
        address owner,
        uint256 depositTime,
        string memory name
    ){

        // 获取原始的存款箱地址，并将其转换为 IDepositBox 接口
        IDepositBox box = IDepositBox(boxAddress);

        // 调用子合约实现：返回所有关键细节
        // 使用场景：构建一个表格或卡片 UI，通过一次调用显示每个用户存款箱的完整摘要——对于高效的前端渲染非常有用。
        return(
            box.getBoxType(),
            box.getOwner(),
            box.getDepositTime(),
            boxNames[boxAddress]
        );
    }

}
