// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day17_SubscriptionStorageLayout.sol";

// 用户直接请求此合约，代理合约
contract SubscriptionStorage is SubscriptionStorageLayout{
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }

    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }

    /* 
        fallback 当合约被调用，但是找不对对应签名的function时
        收到数据但没有匹配函数
    */
    fallback() external payable { 
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");

        // assembly 中是汇编语言 Yul
        assembly {
            // 将传入数据data复制到内存中，从位置0开始到calldatasize()结束
            calldatacopy(0 ,0 ,calldatasize())
            /* 
                delegatecall 获取目标合约impl的函数逻辑，在本合约执行
                gas() 获取剩余gas费用
                impl逻辑合约地址
                0：输入数据位置
                calldatasize()：输入数据长度
                0,0：暂不预留输出空间
            */
            let result := delegatecall(gas(),impl , 0 , calldatasize() , 0, 0)
            // 返回的数据复制回内存
            returndatacopy(0, 0, returndatasize())
    
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /*
        receive
        只处理 空数据 + ETH 转账

| 条件                                 | 调用哪个函数                               |
| -----------------------------       | ------------------------------------ |
| 有 ETH + 空数据 + `receive()` 存在   | `receive()`                          |
| 有 ETH + 空数据 + `receive()` 不存在 | `fallback()`（必须 `payable`，否则 revert） |
| 有 ETH + 非空数据                    | `fallback()`（必须 `payable`，否则 revert） |
| 无 ETH + 函数存在                    | 调用对应函数                               |
| 无 ETH + 函数不存在                  | `fallback()`（如果不存在则 revert）          |

    */
    receive() external payable {}
}