// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout {
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

    // 代理合约自身没有业务逻辑，通过 fallback() 触发实际逻辑合约
    fallback() external payable {
        // 确保已设置逻辑合约
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");

        assembly {
            // 将输入数据（函数签名 + 参数）复制到内存槽 0
            calldatacopy(0, 0, calldatasize())
            // 在逻辑合约上运行此输入
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            // 将逻辑合约执行返回的任何内容复制到内存中
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}