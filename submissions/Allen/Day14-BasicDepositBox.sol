// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Day14-BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox{

    /** 
    Everything it inherits from BaseDepositBox.depositTime
    - Ownership management
    - Secret storing and retrieving
    - Deposit time tracking
    - Access control modifiers
    - Events

    This contract can:
    - Store a secret string (only the owner can set or retrieve it)
    - Transfer ownership to someone else
    - Emit events when secrets are stored or owners are changed
    - Report its own box type as "Basic"

    */
    
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }


}