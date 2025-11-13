//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./SubscriptionLayout.sol";

contract SubscriptionStorage is SubscriptionLayout{
    //代理  存储数据 调用逻辑合约
    modifier onlyOwner(){
       require(msg.sender == owner, "Access Denied");
        _;
    }

    constructor(address _logicAdr){
        owner = msg.sender;
        logicAdr = _logicAdr;
    }

    function upgradeTo(address _newAdr) external onlyOwner{
        logicAdr = _newAdr;
    }

    //  fallback() external payable {
    //     require(logicAdr != address(0), "Invalid address");

    //     assembly {
    //         calldatacopy(0, 0, calldatasize())
    //         let result := delegatecall(gas(), logicAdr, 0, calldatasize(), 0, 0)  
    //上句直接使用继承的logicAdr会报错  要使用本地的存储
    //         returndatacopy(0, 0, returndatasize())

    //         switch result
    //         case 0 { revert(0, returndatasize()) }
    //         default { return(0, returndatasize()) }
    //     }
    // }

     fallback() external payable {
        address impl = logicAdr;
        require(impl != address(0), "Invalid address");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }



    receive() external payable{}



}