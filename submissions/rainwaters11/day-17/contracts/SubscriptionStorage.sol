// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SubscriptionStorageLayout.sol";

/// @title SubscriptionStorage (Proxy)
/// @notice Holds all ETH and persistent state. Delegates every business-logic
///         call to `logicContract` via delegatecall, so the logic contract
///         operates on THIS contract's storage.
///
///         Storage slots mirror SubscriptionStorageLayout exactly — never add
///         variables here that are not in the layout, or slot collisions occur.
contract SubscriptionStorage is SubscriptionStorageLayout {

    // ─── Events ────────────────────────────────────────────────────────────────
    event Upgraded(address indexed previousLogic, address indexed newLogic);

    // ─── Constructor ──────────────────────────────────────────────────────────
    /// @param _logicContract Address of the initial SubscriptionLogicV1 deployment.
    constructor(address _logicContract) {
        require(_logicContract != address(0), "Proxy: zero address");
        owner        = msg.sender;
        logicContract = _logicContract;
        emit Upgraded(address(0), _logicContract);
    }

    // ─── Upgrade ──────────────────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Proxy: not owner");
        _;
    }

    /// @notice Point the proxy at a new logic contract.
    /// @param _newLogic Address of the upgraded implementation (e.g. V2).
    function upgradeTo(address _newLogic) external onlyOwner {
            require(_newLogic != address(0), "Proxy: zero address");
            require(_newLogic.code.length > 0, "Proxy: logic must be contract");
            emit Upgraded(logicContract, _newLogic);
            logicContract = _newLogic;
        }

    // ─── Fallback — delegatecall forwarding ──────────────────────────────────
    /// @notice Forwards all unrecognised calls to `logicContract` via delegatecall.
    ///         The logic contract reads and writes THIS proxy's storage, so state
    ///         is always stored here even as logic is upgraded.
    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Proxy: no logic set");

        assembly {
            // Copy calldata into memory starting at position 0.
            calldatacopy(0, 0, calldatasize())

            // Forward the call.  delegatecall(gas, addr, argsOffset, argsLen, retOffset, retLen)
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // Copy any return data.
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice Accept plain ETH transfers (e.g. subscription payments forwarded without data).
    receive() external payable {
            revert("Proxy: use subscription function");
        }
}
