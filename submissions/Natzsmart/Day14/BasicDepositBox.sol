// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

// Import the BaseDepositBox abstract contract
import "./BaseDepositBox.sol";

// BasicDepositBox inherits from BaseDepositBox
contract BasicDepositBox is BaseDepositBox {

    // Returns the type of the deposit box as a string
    // This function overrides the abstract definition in IDepositBox
    function getBoxType() external pure override returns(string memory) {
        return "Basic";
    }
}