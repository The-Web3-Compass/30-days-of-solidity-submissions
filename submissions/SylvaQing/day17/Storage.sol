// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorageLayout.sol";

// 代理合约
contract SubscriptionStorage is SubscriptionStorageLayout{
    // 保护敏感函数——比如升级合约
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    // 传入初始逻辑合约的地址——通常是 SubscriptionLogicV1
    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }

    // 更新逻辑!!!可以在不触及用户数据或要求人们重新部署的情况下修复错误、添加功能或重构代码
    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }

 
    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    // 一个安全网，允许代理接受原始 ETH 转账;
    // 这里不需要，但当合约直接接收 ETH 时（例如，在支付期间）通常很有用
    receive() external payable {

    }

}