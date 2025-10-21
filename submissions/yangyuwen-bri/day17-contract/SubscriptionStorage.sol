//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout{
    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can perform this action,");
        _;
    }

    constructor(address _logicContract) {
        owner == msg.sender;
        logicContract = _logicContract;
    }

    function upgradeTo(address _newLogic) external onlyOwner{
        logicContract = _newLogic;
    }

    //用逻辑合约的代码，操作代理合约的数据
    fallback() external payable{
        
        address impl = logicContract;
        require(impl != address(0), "logic contract is not set.");

        // ***用内联汇编assembly直接写EVM底层指令***
        assembly{
            
            calldatacopy(0, 0, calldatasize()) // 把用户传入的所有参数复制到内存0位置
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0) // 内联汇编语法 ":=" 等同于"=="
            returndatacopy(0, 0, returndatasize())
            
            switch result
            case 0 { revert(0, returndatasize()) }
            default {return(0, returndatasize())}

        }
        

    }

    receive() external payable{}


}