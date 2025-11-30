// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { SaasStorage } from "./SaasStorage.sol";

/**
 * @title UpgradeHub
 * @dev Build an upgradeable subscription manager for a SaaS-like dApp.
 * The proxy contract stores user subscription info (like plans, renewals, and expiry dates),
 * while the logic for managing subscriptions—adding plans, upgrading users,
 * pausing accounts—lives in an external logic contract.
 * When it's time to add new features or fix bugs,
 * you simply deploy a new logic contract and point the proxy to it using `delegatecall`,
 * without migrating any data.
 * This simulates how real-world apps push updates without asking users to reinstall.
 * You'll learn how to architect upgrade-safe contracts using the proxy pattern and `delegatecall`,
 * separating storage from logic for long-term maintainability.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 17
 */
contract UpgradeHub is SaasStorage {
    constructor() SaasStorage() {
        owner = msg.sender;
    }

    function changeImpl(address newImpl) public onlyOwner {
        require(newImpl != address(0x00), "null address implementation");
        impl = newImpl;
    }

    receive() external payable {
        require(impl != address(0x00), "null address implementation");
        address implLocalVar = impl;

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implLocalVar, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    fallback() external {
        // TODO work out if can call a function without messing up calldata,
        // then move impls into there.
    }
}
