//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Build a modular vault system and lets users store sensitive secrets on-chain in different types of deposit boxed.

// Key idea:
// - some secrets are basic, meant for everyday use;
// - some are premium, offering bonus features like metadata;
// - some are time-locked, where the user can't open the vault until a certain time has passed.

// Interface in solidity:
// If the inheritance is about reusing common logic, interfaces are about enforcing structure.
// An interface in solidity is basically a contract with only function definitions---no logic,no storage,no state variables.
//     Benefits:
//     - It makes contract interactions predictable---even across different types;
//     - It let us write tools that talk to any contract that follows the interface---without knowing the full implementation;
//     - It keeps our system modular and flexible;


// Interface in Solidity:
// An interface is a contract type that declares function signatures only, with no implementation, no state variables, no constructor, and no fallback/receive functions.
// It only has declarations (name, parameters, visibility, state mutability, returns)

// Purpose:
//     -Define a Standard Contract API:
//         -Establishes a fixed, enforceable contract for how functions must be named, parameterized, and return values — enabling standardization across contracts.
//     -Enable Safe Interaction with External Contracts:
//         -Allows a contract to call another contract using a type-safe reference, without needing its full source code.
//     -Support Polymorphism and Upgradability:
//         -Multiple contracts can implement the same interface → your code can work with any of them interchangeably.


// IDepositbox.sol - interface
//     Define a simple rulebook of required functions. Every vault will be required to follow this.

interface IDepositBox{
    function getOwner() external view returns(address);
    function transferOwnership(address newOwner) external;
    // calldata is a non-modifiable, temporary memory area that holds the arguments of an external function call which has cheaper gas fee than "memory"
    // It is part of msg.data – the raw bytes sent with the transaction.
    // It persists for the entire duration of the function execution but cannot be changed.
    // Reasons for calldata here:
    //     -Save Gas
    //         -No bytes are copied from msg.data to EVM memory.
    //         -Especially important for large strings (e.g., long secrets, JSON, IPFS hashes).
    //     -Guarantee Immutability
    //         -The function promises not to modify the input.
    //         -Using calldata enforces this at the compiler level.
    //     -Best Practice for External Functions
    //         -Solidity’s official style guide recommends calldata for all external function parameters that are not modified.
    function storeSecret(string calldata secret) external;
    function getSecret() external view returns(string memory);
    function getBoxType() external pure returns(string memory);
    function getDepositTime() external view returns(uint256);

}