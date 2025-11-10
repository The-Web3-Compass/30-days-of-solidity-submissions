// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout{
    constructor(address _logicContract){
        owner = msg.sender;
        logicContract = _logicContract;
    }

    modifier onlyOwner(){
        require(owner == msg.sender,"not the owner");
        _;
    }

    function upgradeTo(address _newLogic) external onlyOwner{
        logicContract = _newLogic;
    }

    //fallback触发：
    //当调用的函数在合约中不存在时
    //receve触发：
    //当收到普通转账（没有 calldata）时（但没有定义 receive()）
    fallback() external payable{
        address impl = logicContract;
        require(impl != address(0),"invalid contract");

        assembly{
            //把当前未知函数的所有参数复制到内存位置0
            calldatacopy(0,0,calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(),0,0)
            returndatacopy(0,0,returndatasize())

            switch result
            case 0{ revert(0, returndatasize())}
            default { return(0, returndatasize())}
        }
    }

    receive() external payable{}
    //允许接收 ETH，不做任何操作

}