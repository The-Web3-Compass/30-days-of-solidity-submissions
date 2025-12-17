// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Kevin Wallet Proxy
/// @notice 基于 Day17 delegatecall 代理模式的可升级钱包
/// @dev 使用 delegatecall 将所有调用转发到逻辑合约
contract KevinWalletProxy {
    
    // 逻辑合约地址
    address public logicContract;
    // 代理合约的 owner
    address public owner;
    
    event Upgraded(address indexed newLogic);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address _logicContract) {
        require(_logicContract != address(0), "Invalid logic contract");
        logicContract = _logicContract;
        owner = msg.sender;
    }
    
    /// @notice 升级逻辑合约
    /// @param newLogic 新的逻辑合约地址
    function upgradeTo(address newLogic) external onlyOwner {
        require(newLogic != address(0), "Invalid logic contract");
        logicContract = newLogic;
        emit Upgraded(newLogic);
    }
    
    /// @notice Fallback 函数 - 将所有调用委托给逻辑合约
    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");
        
        assembly {
            // 复制 calldata
            calldatacopy(0, 0, calldatasize())
            
            // 使用 delegatecall 调用逻辑合约
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            
            // 复制返回数据
            returndatacopy(0, 0, returndatasize())
            
            // 根据结果返回或 revert
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    
    /// @notice 接收 ETH
    receive() external payable {}
}
