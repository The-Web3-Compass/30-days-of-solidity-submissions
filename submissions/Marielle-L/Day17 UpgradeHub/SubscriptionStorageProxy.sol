//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import"./SubscriptionStorageLayout.sol";

contract SubscriptionStorageProxy is SubscriptionStorageLayout {
    modifier onlyOwner(){
        require(owner == msg.sender,"Not Owner");
        _;
    }

    constructor(address _logicContract){
        owner = msg.sender;
        logicContract = _logicContract;
    }

    function upgradeTo(address newLogic) external onlyOwner{
        logicContract = newLogic;
    }

    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0),"Logic Contract not Set");


//destOffset = 0：表示 复制到内存的起点位置是0
//dataOffset = 0：表示 从 calldata 的第0个字节开始复制
//length = calldatasize()：表示 复制的字节数就是整个调用数据的长度
//接收到用户的调用，把调用转发到逻辑合约，获取返回结果，再原样返回给用户
        assembly{
            calldatacopy(0,0,calldatasize())   //calldatacopy(destOffset, dataOffset, length)
            let result := delegatecall(gas(),impl,0,calldatasize(),0,0) //在 Yul 里，:= 是“赋值操作”的符号，和 Solidity 中的 = 一样
            returndatacopy(0,0,returndatasize())

/*
switch 条件值
case 条件匹配值 {
    // 执行这一段
}
default {
    // 如果没有匹配，就执行这里
}
*/
            switch result  //switch 是条件判断语句，相当于 Solidity 的 if...else
            case 0 {revert(0,returndatasize())} // delegatecall 的返回值是布尔型（bool）
            default {return(0,returndatasize())}
        }
    }

    receive() external payable {}
}
