// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title DelegatecallLib
 * @dev Library for safe delegatecall execution with context preservation
 * 
 * This library handles the low-level delegatecall mechanism, ensuring
 * that the execution context (msg.sender, msg.value, storage) is properly
 * maintained when calling plugin contracts from the main profile contract.
 */
library DelegatecallLib {
    /// Error definitions
    error DelegatecallFailed(address target, bytes data, string reason);

    /**
     * @dev Executes a delegatecall to a target contract
     * 
     * delegatecall is a special call opcode that:
     * - Executes code from the target contract
     * - BUT maintains the caller's storage context
     * - Keeps msg.sender and msg.value as they were
     * - This is crucial for plugins to read/write profile data
     * 
     * @param target The contract address to delegatecall
     * @param data The encoded function call (selector + parameters)
     * @return success Whether the call succeeded
     * @return result The returned data from the delegatecall
     */
    function executeDelegatecall(
        address target,
        bytes memory data
    ) internal returns (bool success, bytes memory result) {
        require(target != address(0), "Target cannot be zero address");
        require(data.length >= 4, "Data must contain function selector");

        // Perform delegatecall
        // This executes the code at target with our storage context
        (success, result) = target.delegatecall(data);

        // Revert if delegatecall failed
        if (!success) {
            // Decode revert reason if available
            if (result.length > 0) {
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(result)
                    revert(add(32, result), returndata_size)
                }
            }
        }
    }

    /**
     * @dev Safely encodes a function call for delegatecall
     * 
     * @param functionSelector The function selector (4 bytes)
     * @param encodedParams The abi-encoded parameters
     * @return The complete encoded call data
     */
    function encodeCall(
        bytes4 functionSelector,
        bytes memory encodedParams
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(functionSelector, encodedParams);
    }

    /**
     * @dev Gets the function selector from a function signature
     * 
     * Example: getSelector("transfer(address,uint256)") returns bytes4
     * 
     * @param signature The function signature as string
     * @return The function selector (first 4 bytes of keccak256)
     */
    function getSelector(string memory signature) internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked(signature)));
    }
}
