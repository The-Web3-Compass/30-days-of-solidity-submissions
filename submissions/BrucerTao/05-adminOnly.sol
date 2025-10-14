// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;  //所有者
    uint256 public treasureAmount;  //宝箱里的宝藏数量
    mapping(address => uint256) public withdrawAllowance; //地址->可提取限额数
    mapping(address => bool) public hasWithdrawn; //地址-> 是否支取
    mapping(address => uint256) public maxWithdrawalLimit; //地址->最大提款限额
    uint256 public cooldownTime = 5 minutes; // 冷却时间，默认5分钟
    mapping(address => uint256) public lastWithdrawTime; // 记录用户上次提款时间
    
    // 事件声明
    event TreasureAdded(address indexed owner, uint256 amount);
    event TreasureWithdrawn(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: you are not owner");
        _;
    }

    //宝箱中添加宝藏
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
        emit TreasureAdded(msg.sender, amount);
    }

    //批准他人提款
    function appproveWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount, "not enough treasure");
        withdrawAllowance[recipient] = amount;
    }

    //设置用户最大提款限额
    function setMaxWithdrawalLimit(address user, uint256 maxLimit) public onlyOwner {
        maxWithdrawalLimit[user] = maxLimit;
    }

    //实际提取宝藏
    function withdrawTreasure(uint256 amount) public {
        if(msg.sender == owner){
            require(amount <= treasureAmount, "not enough treasure");
            treasureAmount -= amount;
            emit TreasureWithdrawn(msg.sender, amount);
            return;
        }
        uint256 allowance = withdrawAllowance[msg.sender];

        require(allowance > 0, "you donet have treasure allowance");
        require(!hasWithdrawn[msg.sender],"you have already withdrawn treasure");
        require(allowance <= treasureAmount, "not enough treasure in chest");
        require(allowance >= amount,"cannot withdraw more than you are allowed");
        require(block.timestamp >= lastWithdrawTime[msg.sender] + cooldownTime, "Cooldown period not over yet");
        
        // 检查是否超过最大提款限额
        uint256 userMaxLimit = maxWithdrawalLimit[msg.sender];
        if(userMaxLimit > 0) {
            require(amount <= userMaxLimit, "withdrawal amount exceeds maximum limit");
        }

        //完成提款
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawAllowance[msg.sender] = 0;
        lastWithdrawTime[msg.sender] = block.timestamp; // 更新上次提款时间
        emit TreasureWithdrawn(msg.sender, allowance);

    }

    //重置用户提款状态
    function resetWithdrawlStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;

    }
    
    //设置冷却时间
    function setCooldownTime(uint256 newCooldownTime) public onlyOwner {
        cooldownTime = newCooldownTime;
    }

    //转让所有权
    function transferOnwership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    //查看宝藏
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;

    }

    // 检查用户批准状态和提款状态
    function checkUserStatus(address user) public view returns (bool isApproved, bool hasWithdrawnStatus, uint256 allowanceAmount, uint256 maxLimit) {
        isApproved = withdrawAllowance[user] > 0;
        hasWithdrawnStatus = hasWithdrawn[user];
        allowanceAmount = withdrawAllowance[user];
        maxLimit = maxWithdrawalLimit[user];
    }


}