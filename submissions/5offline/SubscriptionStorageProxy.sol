//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day17SubscriptionStorageLayout.sol";
//导入后写代理合约
//确保了 proxy 具有与 logic contract 相同的变量结构
contract SubscriptionStorageProxy is SubscriptionStorageLayout {
    //继承了前一个合同的变量以及逻辑
    //信息存在proxy这里

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor(address _logicContract) {

        owner = msg.sender;
        logicContract = _logicContract;
        //将逻辑合约的地址传递给proxy
       // 逻辑合约中的owner就是proxy,所以可以直接访问其变量

}
    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }
    //重要功能,改变逻辑不变数据

        fallback() external payable {
            //特殊函数，没有名字，不能有参数，也不能有返回值。
            //接收到以太币但没有匹配的函数调用
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");
        //新东西，回退函数，impl是变量名字
        //callback 函数通常用来捕获所有未明确声明的调用，并将其委托（delegatecall）到逻辑合约

        assembly {
            //assembly（内联汇编）
            calldatacopy(0, 0, calldatasize())
            //把调用合约时传入的所有数据，复制到内存的起始位置（0）。

            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            //用 delegatecall 调用`impl`（实现合约）的逻辑。
            //gas()，把当前剩余的 gas 全部给 delegatecall。0：输入数据在内存的起始位置
            //calldatasize()输入数据的长度
            //0：输出数据在内存的起始位置、长度
            returndatacopy(0, 0, returndatasize())
            //这是代理合约（Proxy）的核心转发逻辑
            //写法不一样，当作模版来看

            switch result
            case 0 { revert(0, returndatasize()) }
            //失败时调用revert （将当前位置的数据复制到调用上），并返回 0，0：输出数据在内存的起始位置、长度。
            //returndatasize()输出数据的长度
            //case 0 =当 result 等于 0 时（即 delegatecall 失败）
            default { return(0, returndatasize()) }
            //成功时，将结果返回给原始调用者 — 就像代理自己执行了它一样
            //当 result 不等于 0 时（即 delegatecall 成功）
        }

        }
         receive() external payable {}
         //一个安全网，允许代理接受原始 ETH 转账 。
         //应付外界的转账
        
}
//1:0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
//2:0x358AA13c52544ECCEF6B0ADD0f801012ADAD5eE3
//proxy：0xf8e81D47203A594245E36C48e151709F0C19fBe8

            


        
