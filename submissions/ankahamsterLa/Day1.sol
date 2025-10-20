// SPDX-License-Identifier: MIT
//This is a standard way to specify the legal permissions and restrictions associated with the code.
pragma solidity ^0.8.0;// declare version of solidity language

//define smart contract
contract ClickCounter {
    // decalre a state variable named counter;
    // uint256 is a data type that represents an unsigned integer, meaning it can only store positive numbers (0 and above).
    // public makes the variable accessible to anyone. Solidity automatically creates a getter function
    uint256 public counter;

    // Setting function which can modify the state variable performs a state-changing operation. So that it requires gas fees to execute.
    function click() public {
        counter++;
    }
}