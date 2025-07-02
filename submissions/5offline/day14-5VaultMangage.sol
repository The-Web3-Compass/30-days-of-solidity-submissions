//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeblockBox.sol";
//不需要base的那个因为是抽象函数，这些合同都在用

contract VaultManager {
    mapping(address => address[]) private userDepositBoxes;
    //DepositBoxes以 address（地址）形式存在，因为每个保险箱本质上是一个独立的智能合约实例。
    mapping(address => string) private boxNames;

    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    //看用户想要储存的信息，创建的盒子

    event BoxNamed(address indexed boxAddress, string name);
    //用户的盒子命名
    function createBasicBox() external returns (address) {
    BasicDepositBox box = new BasicDepositBox();
    // new表示在区块链上部署一个全新的 BasicDepositBox 合约。
    //部署一个新的 BasicDepositBox 合约，变量名字叫box
    //保险箱的创建是没有数量限制的。你可以为自己创建任意数量的 Basic、Premium 或 TimeLocked 保险箱

    userDepositBoxes[msg.sender].push(address(box));
    //存到 mapping 里
    emit BoxCreated(msg.sender, address(box), "Basic");
    return address(box);
    //从前面的合约里再创造一个新的合约
    //每次创建一个新的保险箱（如 BasicDepositBox），都需要部署一个新的合约
    //这些保险箱的设计初衷是存储“秘密”或敏感信息
}
//元数据：metadata：你在保险箱里存了一个密码，元数据可以写成“我的邮箱密码”。
// 一般来说，元数据里几十到几百个字没问题，写到几千字也能存，但不建议太长。

function createPremiumBox() external returns (address) {
    PremiumDepositBox box = new PremiumDepositBox();
    userDepositBoxes[msg.sender].push(address(box));
    //存mapping
    emit BoxCreated(msg.sender, address(box), "Premium");
    return address(box);
}//一样的程序
//在同一个函数或代码块里，变量名不能重复，但在不同函数里可以用同样的变量名。都叫box
//创建时没有写metadata，后面可以分离操作

function createTimeLockedBox(uint256 lockDuration) external returns (address) {
    //秒钟计数，可以用在时间胶囊上，在某个时间说新年快乐
    TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);
    //里面会放lockduration的时间
    userDepositBoxes[msg.sender].push(address(box));
    //该合约跟踪谁拥有哪些盒子，而不会在链上存储完整的用户数据
    emit BoxCreated(msg.sender, address(box), "TimeLocked");
    return address(box);
}
function nameBox(address boxAddress, string calldata name) external {
    //触发别的地址
    IDepositBox box = IDepositBox(boxAddress);
    //boxAddress是一个合约地址，指向某个已经部署好的保险箱（DepositBox）合约。
    //把 boxAddress 这个地址“转型”为 IDepositBox 类型的变量 box
    //遵守规则就可以交互
    require(box.getOwner() == msg.sender, "Not the box owner");
    // 这个条件语句，只有保险箱持有人（拥有保险箱的地址），才能操作保险箱。
        //如果不是这个人，会抛出异常
    boxNames[boxAddress] = name;
    //给某个保险箱（用地址标识）起一个名字，并把这个名字存到链上。
    emit BoxNamed(boxAddress, name);
}
function storeSecret(address boxAddress, string calldata secret) external {
    IDepositBox box = IDepositBox(boxAddress);
    require(box.getOwner() == msg.sender, "Not the box owner");
    //和上面一样的
    box.storeSecret(secret);
    //调用保险箱的 storeSecret 函数，把 secret 这个秘密写进保险箱的链上存储空间。
    //不是metadata
    //之前emit过了

}
function transferBoxOwnership(address boxAddress, address newOwner) external {
    //换owner
    IDepositBox box = IDepositBox(boxAddress);
    require(box.getOwner() == msg.sender, "Not the box owner");
    //和上面一样
    box.transferOwnership(newOwner);
    //把保险箱的所有权转让给 newOwner 这个新地址
    //xx= newowner，只适合简单的变量赋值，但如果涉及到权限管理、事件记录、合约继承等复杂场景，用函数
    address[] storage boxes = userDepositBoxes[msg.sender];
    //获取发件人的框列表，当前调用者的地址是xx
    for (uint i = 0; i < boxes.length; i++) {
        {
        if (boxes[i] == boxAddress) {
            boxes[i] = boxes[boxes.length - 1];
            //交换，把要删的元素位置用数组最后一个元素覆盖
            //假如 boxes = [A, B, C, D]，要删 B，那执行完这一行后，boxes = [A, D, C, D]。
            boxes.pop();
            //删掉的是最后一个元素D，因为已经ADC
            break;}
            //后来加的if，不然提示语法错误
        }
        //高效删除元素、节省 gas
        //为了维护用户与 box 的关联状态一致、减少存储压力、避免数据重复或冲突。
        userDepositBoxes[newOwner].push(boxAddress);
        //把这个 boxAddress 添加到 newOwner 对应的数组里
        //一个完整的 box 转让流程（从老用户解绑 → 新用户绑定）。
    }
    }

    function getUserBoxes(address user) external view returns (address[] memory) {
    return userDepositBoxes[user];
}//用来列出用户的mapping

function getBoxName(address boxAddress) external view returns (string memory) {
    return boxNames[boxAddress];
}//返回盒子名字值

function getBoxInfo(address boxAddress) external view returns (
    string memory boxType,
    address owner,
    uint256 depositTime,
    string memory name
    //多合一辅助函数
) {
    IDepositBox box = IDepositBox(boxAddress);
    //调用返回详细信息
    return (
        box.getBoxType(),
        box.getOwner(),
        box.getDepositTime(),
        boxNames[boxAddress]
    );
}


}