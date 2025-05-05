// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SubscriptionStorage.sol";

/**
 * @title SubscriptionManagerProxy
 * @author Your Name
 * @notice A simple proxy contract for managing upgradeable subscription logic.
 * @dev Stores user data and delegates all logic calls to a separate implementation contract.
 * @dev Follows a basic proxy pattern using delegatecall. Does not use standardized proxy patterns like UUPS or Transparent Proxy for simplicity.
 */
contract SubscriptionManagerProxy is SubscriptionStorage {
    /// @notice Address of the logic contract.
    address internal _logicContractAddress;

    /**
     * @notice Emitted when the logic contract address is updated.
     * @param previousAddress The address of the old logic contract.
     * @param newAddress The address of the new logic contract.
     */
    event Upgraded(address indexed previousAddress, address indexed newAddress);

    /**
     * @notice Emitted when the ownership of the proxy is transferred.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Modifier to restrict function calls to the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != _getOwner()) revert NotOwner();
        _;
    }

    /**
     * @notice Initializes the proxy contract.
     * @param initialLogicAddress The address of the first logic contract implementation.
     * @dev Sets the deployer as the initial owner. Initializes `nextPlanId` to 1.
     */
    constructor(address initialLogicAddress) {
        _setOwner(msg.sender);
        _logicContractAddress = initialLogicAddress;
        nextPlanId = 1;
        emit OwnershipTransferred(address(0), msg.sender);
        emit Upgraded(address(0), initialLogicAddress);
    }

    /**
     * @notice Allows the owner to upgrade the logic contract address.
     * @param newLogicAddress The address of the new logic contract implementation.
     * @dev Emits {Upgraded}.
     */
    function upgradeTo(address newLogicAddress) external onlyOwner {
        address oldLogicAddress = _logicContractAddress;
        _logicContractAddress = newLogicAddress;
        emit Upgraded(oldLogicAddress, newLogicAddress);
    }

    /**
     * @notice Allows the current owner to transfer control of the proxy to a new owner.
     * @param newOwner The address of the new owner.
     * @dev Emits {OwnershipTransferred}.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert("Owner cannot be zero address");
        address oldOwner = _getOwner();
        _setOwner(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Returns the address of the current logic contract.
     * @return logicAddress The implementation address.
     */
    function getLogicAddress() external view returns (address logicAddress) {
        return _logicContractAddress;
    }

    /**
     * @notice Returns the address of the owner.
     * @return ownerAddress The owner address.
     */
    function owner() external view returns (address ownerAddress) {
        return _getOwner();
    }

    /**
     * @notice Fallback function to delegate calls to the logic contract.
     * @dev Uses `delegatecall` to execute logic contract code in the context of this proxy's storage.
     * @dev Handles return data and reverts appropriately.
     */
    fallback() external payable {
        _delegate(_logicContractAddress);
    }

    /**
     * @notice Receive function to accept Ether transfers (if needed by logic, e.g., for paid subscriptions).
     * @dev Currently does nothing but allows the proxy to receive Ether.
     */
    receive() external payable {
        _delegate(_logicContractAddress);
    }

    /**
     * @notice Internal function to delegate calls to the logic contract.
     * @param _implementation The address of the logic contract to call.
     * @dev This function is used by fallback() to execute logic contract code.
     * @dev This function is copied from https://solidity-by-example.org/app/upgradeable-proxy/
     */
    function _delegate(address _implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.

            // calldatacopy(t, f, s) - copy s bytes from calldata at position f to mem at position t
            // calldatasize() - size of call data in bytes
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.

            // delegatecall(g, a, in, insize, out, outsize) -
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error (eg. out of gas) and 1 on success
            let result := delegatecall(
                gas(),
                _implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            // returndatacopy(t, f, s) - copy s bytes from returndata at position f to mem at position t
            // returndatasize() - size of the last returndata
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                // revert(p, s) - end execution, revert state changes, return data mem[p…(p+s))
                revert(0, returndatasize())
            }
            default {
                // return(p, s) - end execution, return data mem[p…(p+s))
                return(0, returndatasize())
            }
        }
    }
}
