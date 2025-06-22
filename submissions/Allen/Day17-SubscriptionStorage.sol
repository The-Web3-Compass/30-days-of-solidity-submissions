// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout{

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }


    constructor(address _logicContract){
        logicContract = _logicContract;
        owner = msg.sender;

    }

    /**
    When this happens, the storage stays the same, 
    but all new interactions will use the new logic.
    */
    function upgradeTo(address _newLogic) public onlyOwner{
        require(_newLogic != address(0),"Invaild address");
        logicContract = _newLogic;
    }

    /**
    fallback:It’s a special function that gets triggered whenever a user calls a function 
    that doesn’t exist in this proxy contract.

    */
    fallback() external payable{
        // Make sure a logic contract has been set.Store it in impl.
        address impl = logicContract;
        require(impl != address(0),"Invaild address");

        assembly{
            // Copy the input data (function signature + arguments) to memory slot 0.
            calldatacopy(0,0,calldatasize())
            // Runing this input on the logic contract (impl)…
            // delegatecall runs the logic code, but uses this proxy’s storage and this proxy’s context.
            let result := delegated(gas(),impl,0,calldatasize(),0,0)
            // Copy whatever came back from the logic contract’s execution to memory.
            // Could be a return value or an error message.
            returndatacopy(0,0,returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }

        }
    }

    // A safety net that lets the proxy accept raw ETH transfers.
    receive() external payable {}


}