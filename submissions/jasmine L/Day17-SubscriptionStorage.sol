// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day17-SubscriptionStorageLayout.sol";
/**
 * @title SubscriptionStorage
 * @notice 代理合约
 * @dev 拥有数据，通过 delegatecall 将所有逻辑委托给外部合约执行，可以随时升级到新的逻辑合约
 */
contract SubscriptionStorage is SubscriptionStorageLayout{
    modifier onlyOwner(){
        require(msg.sender == owner, "No permission!");
        _;
    }

    constructor (address _logicContract) {
        owner = msg.sender;
        subscriptionLogicAddress = _logicContract;
    }
    
    function upgradeTo(address _newLogicAddress) external onlyOwner{
        subscriptionLogicAddress = _newLogicAddress;
    }
    
    //内联汇编
    /*函数选择器找不到
    * 或有数据但没匹配到任何函数签名时走它（然后转发给实现）
    */
    fallback() external payable {
        address impl = subscriptionLogicAddress;//已经设置好逻辑合约
        require(impl !=address(0),"Logic contract not set");
        
        assembly {
            // 复制调用数据到内存!
            calldatacopy(0, 0, calldatasize())
            // 执行delegatecall
            // 参数：全部 gas、目标地址 impl、输入内存起点0、长度=calldatasize、
            //         输出缓冲起点0、长度0（先不分配，等返回后再拷）
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
           
            // 复制返回数据
            returndatacopy(0, 0, returndatasize())
            
            //根据结果返回或回滚
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    // receive()：只收 ETH 且 calldata 为空时走
    receive() external payable {}
}
