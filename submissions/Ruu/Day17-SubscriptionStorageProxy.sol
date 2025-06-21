//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorageProxy is SubscriptionStorageLayout{

    modifier OnlyOwner{
        require(msg.sender == Owner, "Not the owner");
        _;
    }

    constructor(address _logiccontract){
        Owner = msg.sender;
        LogicContract = _logiccontract;
    }

    function UpgradeTo(address _newlogic) external OnlyOwner{
        LogicContract = _newlogic;
    }

    fallback() external payable{
        address impl = LogicContract;
        require(impl != address(0), "Logic contract is not set");
        assembly{
            calldatacopy(0,0,calldatasize())
            let result := delegatecall(gas(),impl,0,calldatasize(),0,0)
            returndatacopy(0,0,returndatasize())
            switch result
            case 0 {revert(0,returndatasize())}
            default {return(0,returndatasize())}
        }
    }

    receive() external payable{}
}
