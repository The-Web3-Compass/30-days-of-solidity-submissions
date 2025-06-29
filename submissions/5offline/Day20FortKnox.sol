//FortKnox: The Reentrancy Heist” 是一个典型的以太坊智能合约安全攻击案例教学项目或靶场（CTF题目），用于帮助开发者学习智能合约中的**重入攻击（Reentrancy Attack）**漏洞。
//这是以太坊历史上最臭名昭著的漏洞之一，最著名的例子是 The DAO 攻击（2016年），攻击者通过反复调用提现函数，从合约中反复取出资金，直到资金被掏空。
//这是一个教学/训练项目，目的是：
//模拟一个看起来安全的“保险库合约”——FortKnox；
//引导你利用其内部的重入漏洞；
//学会如何进行攻击，以及 更重要的：如何防御重入攻击。
//重新输入相同的函数 — 在它完成第一次运行之前，在更新余额之前不断写fallback来提取资金
//写2份合同，容易被攻击的、攻击的

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GoldVault {
    //被攻击再修复，首先是存款和取款
    //再用黑客手段去攻击
     uint256 private _status;
    //我存钱/取钱的活动有没有在做
    uint256 private constant _NOT_ENTERED = 1;
    //没人进入1
    uint256 private constant _ENTERED = 2;
    //有人进入2:数字锁

        mapping(address => uint256) public goldBalance;
    //看用户有多少余额
    constructor() {
    _status = _NOT_ENTERED;
//初始时是1
    }
    modifier nonReentrant() {
        //以前都是owner条件，这是一个安全条件
    require(_status != _ENTERED, "Reentrant call blocked");
    //这个功能里已经有人了吗？立即使用 revert  阻止它
    _status = _ENTERED;
    _;
    //锁门行动，运行逻辑
    _status = _NOT_ENTERED;
    //开门行动，运行完逻辑之后再来开门
    //一次只能有一个调用位于受保护函数内，就算fallback来了但是会被阻挡
}
     function deposit() external payable {
     require(msg.value > 0, "Deposit must be more than 0");
     //存钱过程
     goldBalance[msg.sender] += msg.value;
}

      function vulnerableWithdraw() external {
        //故意进行的有漏洞的功能
      uint256 amount = goldBalance[msg.sender];
      require(amount > 0, "Nothing to withdraw");
      //取款的条件
      (bool sent, ) = msg.sender.call{value: amount}("");
      //call来取钱
      require(sent, "ETH transfer failed");
 
      goldBalance[msg.sender] = 0;
     //把余额写回0
     //顺序是关键：1 require这里看了账户的钱 有钱 继续
     //2 = msg.sender.call{value: amount}这里去了msg.sender的账户
     //如果它是合约，一进入合约就自动receive然后重复刚才的功能
     //还没到最后一行之前就会反复进入
     //在状态更新之前就有外部进入了
}

      function safeWithdraw() external nonReentrant {
        //安全的取款
      uint256 amount = goldBalance[msg.sender];
      require(amount > 0, "Nothing to withdraw");
      //这里相同的
      goldBalance[msg.sender] = 0;
      // 安全的，重入攻击之前把余额写回0
      (bool sent, ) = msg.sender.call{value: amount}("");
      require(sent, "ETH transfer failed");
}//换了一个顺序，就会先打破循环
//还有额外的一个防护系统：nonReentrant 的修饰符，有人进入该函数时，它会将其锁定
//“Checks-Effects-Interactions”顺序很重要
//合约状态已经安全地更新了，才与外界交互






    

}