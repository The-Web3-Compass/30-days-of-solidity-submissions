// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout{
    modifier onlyOwner(){
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _logicContract){
        owner = msg.sender;
        logicContract = _logicContract;
    }

    function updateTo(address _newLogicContract)external onlyOwner{
        logicContract = _newLogicContract;
    }

    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");

        //通过 EVM 底层指令，精准实现「拷贝调用数据 → 执行 delegatecall 转发 → 拷贝返回数据 → 处理结果（返回 / 回滚）」的代理逻辑
        assembly {
            //把「调用者发送的Calldata」拷贝到EVM内存
            calldatacopy(0, 0, calldatasize())
            //执行delegatecall，转发调用给逻辑合约
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            //把「逻辑合约的返回数据」拷贝到EVM内存
            returndatacopy(0, 0, returndatasize())

            //根据delegatecall结果，决定是返回数据还是回滚
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
     }
     receive() external payable {}
}