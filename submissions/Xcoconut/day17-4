// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day17 SubscriptionStorageLayout.sol";


contract SubscriptionStorage is SubscriptionStorageLayout {

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /**
     * @dev 构造函数，在部署时设置所有者和初始逻辑合约地址。
     */
    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }

    /**
     * @dev 升级实现合约的地址。
     */
    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }

    /**
     * @dev fallback 函数，将所有调用委托给逻辑合约。
     */
    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");

        assembly {
            // 将调用数据(calldata)复制到内存
            calldatacopy(0, 0, calldatasize())
            // 执行 delegatecall
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            // 将返回数据(returndata)复制到内存
            returndatacopy(0, 0, returndatasize())

            // 根据执行结果处理：如果失败则回滚，如果成功则返回
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev 允许代理合约接收ETH。
     */
    receive() external payable {}
}
