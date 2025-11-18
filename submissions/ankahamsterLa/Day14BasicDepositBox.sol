//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// BasicDepositBox.sol - standard vault
//    Only have the ability/fuctions from the interface. It is a default vault.
// Add one specific label to identify this type of box.
import "./Day14BaseDepositBox.sol";
contract BasicDepositBox is BaseDepositBox{
    // override the getBoxType() declared in "IDepositBox"
    function getBoxType() external pure override returns(string memory){
        return "Basic";
    }

}