//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
// This is the proxy contract: owns the data, delegates all the logic to external contract via delegatecall and upgrade to a new logic contract at any time.
// When users interact with this contract,it is just forwarding their calls to whatever logic contract it's currently pointing to.

// "delegatecall" means code runs from logic contract but storage belongs to proxy. 
import "./Day17SubscriptionStorageLayout.sol";
 contract SubscriptionStorage is SubscriptionStorageLayout{
    modifier onlyOwner(){
        require(msg.sender==owner,"Not owner");
        _;
    }

    constructor(address _logicContract){
        owner=msg.sender;
        logicContract=_logicContract; // Pass in the address of initial logic contract---"SubscriptionLogicV1"
    }

    // It can fix bugs, add features or refactor code without ever touching user data or asking people to redeploy.
    function upgradeTo(address _newLogic) external onlyOwner{
        logicContract=_newLogic; // It updates logicContract to point to a new contract (like "SubscriptionV2").
    }

    // Fallback part: the most critical part of the whole proxy setup.
    // *** It is a special function that gets triggered when a user calls a function that doesn't exist in this proxy contract.***
    // Calling a non-existent function in a Solidity contract triggers the fallback() function, allowing the contract to handle the call flexibly — such as receiving ETH, executing custom logic, forwarding the call, or reverting — with behavior entirely defined by the contract's implementation.


    fallback() external payable{
        address impl=logicContract;
        require(impl!=address(0),"Logic contract not set");

        // Assembly (inline assembly) in Solidity is a way to write low-level EVM (Ethereum Virtual Machine) bytecode directly within your Solidity smart contracts using the assembly {} block.
        // Assembly language is a low-level programming language that is closely tied to a specific computer architecture or virtual machine. It uses mnemonic codes (like ADD, MLOAD, JUMP) to represent machine-level instructions (opcodes).Each mnemonic corresponds one-to-one (or nearly so) with a binary machine code instruction that the processor or virtual machine executes.
        // Assembly is critical in upgradeable contracts because it enables low-level, gas-efficient, and precise control over delegatecall, memory management, and return data handling — which cannot be fully achieved with high-level Solidity — to safely forward arbitrary function calls to an implementation contract while preserving storage context.
        // Assembly in upgradeable contracts is not about "transferring data", but about efficiently, securely, and completely forwarding calls to the new logic — while the old data remains permanently in the proxy contract, without ever needing to be moved.
        assembly{
            // calldatasize(): the size of incoming msg.data
            // calldatacopy(destOffset, dataOffset, length)
            // Copies length bytes from msg.data starting at dataOffset to memory at destOffset
            // copy the input data(function signature+arguments) to memory slot 0

            // destOffset:Destination offset in memory — where to write the data
            // dataOffset:Source offset in calldata — where to read from
            // **Role:Prepare function call**
            calldatacopy(0,0,calldatasize())

            // "delegatecall" runs the logic code but uses this proxy's storage and context
            // Declare and assign a local variable result
            // delegatecall(...):Execute code in another contract (impl) using the current contract’s storage context
            // gas():Pass all remaining gas to the call
            // impl:Address of the implementation (logic) contract
            // 0, calldatasize():Input: memory from 0 to calldatasize() (the copied calldata)
            // 0, 0:Output: write return data starting at memory 0, length 0 (will be filled by callee)
            // **Role:Execute upgradable code**
            let result:=delegatecall(gas(),impl,0,calldatasize(),0,0)

            // Copy whatever came back from the logic contract's execution to memory. Could be a return value or an error message.
            // Copy the return data (e.g., function result, error message) from the delegatecall into memory.
            // returndatacopy(destOffset, dataOffset, length):Copy length bytes of return data to memory at destOffset
            // returndatasize():Returns the size of the return data from the last external call (delegatecall)
            // 0, 0, returndatasize():Copy all return data to memory position 0
            // **Role:Capture result/error**
            returndatacopy(0,0,returndatasize())
            

            // Conditional branching means executing different code paths based on a condition.
            // In high-level languages: if (x == 0) { ... } else { ... }
            // In EVM assembly: switch + case / default = low-level conditional branching.
            // **Role:Return correct response**
            // switch <expression>: Evaluate <expression> (result) and jump to matching case
            switch result
            // case <value> { ... }:If <expression> == <value>, execute the block
            // "case 0": If delegatecall failed (result == 0)
            case 0 {revert(0,returndatasize())}// "revert(offset, size)":Abort transaction and return size bytes from memory at offset
            // default { ... }: If no case matches, execute this block
            // "default": If delegatecall succeeded (result == 1)
            default{return(0,returndatasize())}// "return(offset, size)":End transaction successfully and return size bytes from memory at offset
        }
    }

    // Lets the proxy accept raw ETH transfers
    receive() external payable{}

 }