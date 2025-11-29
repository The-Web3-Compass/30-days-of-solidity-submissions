// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day17-SubscriptionStorageLayout.sol";
contract SubscriptionStorage is SubscriptionStorageLayout {//合约继承

modifier onlyOwner(){
    require(msg.sender==owner,"Not owner");//判断是否是管理员
    _;
}
constructor(address _logicContract){
    owner=msg.sender;
    logicContract = _logicContract;
}

function upgradeTo(address _newLogic) external onlyOwner{
    logicContract=_newLogic;
}

fallback() external payable{//当用户调用此代理合约中不存在的函数时会被触发
    address impl=logicContract;
    require(impl!=address(0),"logic contract not set");
    assembly{
        calldatacopy(0,0,calldatasize())//复制数据到内存 
        //内存起始位置0 调用数据起始位置0 获取调用数据的总字节大小。
        let result:=delegatecall(gas(),impl,0,calldatasize(),0,0)
        //:= 是赋值操作符，这里是将 delegatecall 的执行结果（成功返回 1，失败返回 0）赋值给 result
        //执行委托调用。转发的 Gas 量，impl目标合约地址，0内存起始位置，字节大小，返回内存起始位置，返回字节大小
        returndatacopy(0,0,returndatasize())//从返回数据缓冲区（Return Data Buffer）复制数据到内存。

        switch result
        case 0 {revert(0,returndatasize())}
        default{return(0,returndatasize())}

    }

}
receive() external payable{}


}