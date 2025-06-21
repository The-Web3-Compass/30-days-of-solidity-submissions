//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
 
 //The Standard Vault
import "./2-BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox {
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}
