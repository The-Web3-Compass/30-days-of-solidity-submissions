 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day17-SubscriptionStorageLayout.sol";

// 实际存储storage的合约
contract SubscriptionStorage is SubscriptionStorageLayout {
    // 只有owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    // 输入逻辑合约的地址，需要先把layout合约部署起来
    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }
    // 输入逻辑version的地址，需要把V1和V2部署起来，升级到另外一个合约
    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }

    // 对当前指示的logic合约进行交易操作
    // fallback函数本身没有逻辑，只有在用户与其他合约的function交互时才会触发
    fallback() external payable {
        // 确保合约set成功
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");

        assembly {
            calldatacopy(0, 0, calldatasize())
            // 在这个合约中存储storage和context，但是执行其他的逻辑
            // 地址存放在impl中，这个就指示了另外一个合约
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            // 结果如果为0，会revert一个error
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}


// day17
// 1. 把其他走逻辑的合约进行部署后，复制到这里的address可以进行部署
// 2. 