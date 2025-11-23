//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day14-IDepositBox.sol";

//这个类相当于一个“模板”，其他具体的存款盒，会继承它来完成具体实现
abstract contract BaseDepositBox is IDepositBox {

    //定义了 3 个私有状态变量
    address private owner;     //owner：当前存款盒的拥有者地址
    string private secret;     //secret：存放秘密字符串
    uint256 private  depositTime;    //depositTime：存款盒创建时的时间戳（单位秒）

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);     //OwnershipTransferred：当所有权转移时触发，记录前任和新任所有者地址
    event SecretStored(address indexed owner);     //SecretStored：当新的秘密被存储时触发，记录执行操作的地址

    modifier onlyOwner() {     //定义了一个 修饰符（modifier），名为 onlyOwner，修饰符可以在函数定义中使用，用来限制访问权限，即用于保护敏感函数，使只有盒子拥有者才能调用
        require(msg.sender == owner, "Not the box owner");     //确认调用者必须是当前 owner，否则交易会被回滚（revert）并显示错误信息
        _;
    }

    //定义合约的构造函数（constructor），在部署时执行一次，自动初始化所有者与存款时间
    constructor() {
        owner = msg.sender;     //部署该合约的人（部署者）自动成为存款盒的所有者
        depositTime = block.timestamp;     //记录部署合约时的区块时间（即创建时间）
    }

    //实现接口中的 getOwner() 函数，返回当前存款盒的所有者地址
    function getOwner() public view override returns (address) {
        return owner;
    }

    //允许当前所有者安全地转让合约所有权
    function transferOwnership(address newOwner) external virtual override onlyOwner {     //检查 newOwner 地址是否为零地址（防止错误转移到不存在的账户）
        require(newOwner != address(0), "New owner cannot be zero address");     //触发事件 OwnershipTransferred，记录所有权变更
        emit OwnershipTransferred(owner,newOwner);     //更新 owner 为新的地址
        owner = newOwner;
    }

    //存储秘密内容，盒子所有者保存一个机密信息，比如密码、哈希或备注
    function storeSecret(string calldata _secret) external virtual override onlyOwner { 
    //string calldata _secret：输入参数为字符串，存在 calldata 中（只读高效）
    //virtual override：实现接口，允许子类重写

        secret = _secret;
        emit SecretStored(msg.sender);
    }

    //读取秘密内容，返回存储的秘密字符串，仅限所有者访问
    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }
    
    //返回创建该存款盒的时间戳，用于查询盒子创建的时间，比如计算“存放时长”
    function getDepositTime() external view virtual  override returns (uint256) {
        return depositTime;
    }


