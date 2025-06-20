# Day 17 of 30

Concepts

- Upgradeable contracts
- proxy pattern
- delegate call for upgrades

Progression

- Applies `delegatecall` to contract upgrades.

Example Application

Build an upgradeable subscription manager for a SaaS-like dApp. The proxy contract stores user subscription info (like plans, renewals, and expiry dates), while the logic for managing subscriptions—adding plans, upgrading users, pausing accounts—lives in an external logic contract. When it's time to add new features or fix bugs, you simply deploy a new logic contract and point the proxy to it using `delegatecall`, without migrating any data. This simulates how real-world apps push updates without asking users to reinstall. You'll learn how to architect upgrade-safe contracts using the proxy pattern and `delegatecall`, separating storage from logic for long-term maintainability.

[SubscriptionLogic - sepolia Contract]()
[UpgradeHub - sepolia Contract]()

## Deploying Guide

- Deploy SubscriptionLogic
  - get contract address (`0x63Ebf474070977073E65D00f0E23d9aB62eF7a93`)
- Deploy UpgradeHub
  - use SubscriptionLogic contract address as `_implementation`

**Sepolia**

- [SubscriptionLogic](https://sepolia.etherscan.io/address/0x63Ebf474070977073E65D00f0E23d9aB62eF7a93)
- [UpgradeHub](https://sepolia.etherscan.io/address/0x5ac92f85bfdbc84b1251f4fcb83d60ca85447a10)

## UpgradeHub Contract Testing Guide

### Test Subscription Functionality

Interact with the `UpgradeHub` contract (proxy) to test the delegated functionality from `SubscriptionLogic`. All interactions should use the `UpgradeHub` contract address, as it delegates calls to `SubscriptionLogic`.

#### Add a Subscription Plan

1. Expand the `UpgradeHub` contract.
2. Call the `getAdmin` function to verify the admin is your account (the deployer).
3. Call the `addPlan` function with:
   - `_name`: `"Basic"` (string)
   - `_duration`: `2592000` (uint256, 30 days in seconds)
   - `_price`: `1000000000000000000` (uint256, 1 ETH in wei)
4. Verify the plan was added:
   - Call `getPlan` with `_planId: 1` to retrieve the plan details (`name`, `duration`, `price`, `exists`).
   - Confirm `exists` is `true` and other values match the input.

#### Subscribe to a Plan

1. Switch to a different test account in Remix’s **Account** dropdown (or MetaMask for a test network).
2. Call the `subscribe` function on `UpgradeHub` with:
   - `_planId`: `1` (uint256)
   - **Value**: `1000000000000000000` (1 ETH in wei, matching the plan price).
3. Verify the subscription:
   - Call `getSubscription` with `_user: <your_test_account_address>` to check the subscription details (`planId`, `startDate`, `expiryDate`, `isActive`).
   - Confirm `isActive` is `true` and `expiryDate` is approximately `startDate + 30 days`.

#### Upgrade a Subscription

1. Using the same test account, call `upgradePlan` with:
   - `_newPlanId`: `1` (uint256, assuming another plan isn’t added for simplicity)
   - **Value**: `1000000000000000000` (1 ETH in wei).
2. Verify the subscription updated:
   - Call `getSubscription` again to confirm `planId` and `expiryDate` reflect the new plan.

#### Pause and Resume Subscription

1. Call `pauseSubscription` with the test account.
2. Verify the subscription is paused:
   - Call `getSubscription` and confirm `isActive` is `false`.
3. Call `resumeSubscription` with the same account.
4. Verify the subscription is resumed:
   - Call `getSubscription` and confirm `isActive` is `true`.

### 6. Test Contract Upgrade

To simulate a real-world upgrade, deploy a new `SubscriptionLogic` contract and update the proxy to point to it.

1. **Modify and Deploy New Logic Contract**:

   - In Remix, create a new file (e.g., `SubscriptionLogicV2.sol`).
   - Copy the `SubscriptionLogic` contract code from `UpgradeHub.sol`.
   - Add a new function (e.g., a simple getter for testing upgrades):
     ```solidity
     function getVersion() external pure returns (string memory) {
         return "V2";
     }
     ```
   - Ensure the storage layout (first five variables: `placeholderImplementation`, `placeholderAdmin`, `subscriptions`, `plans`, `planCount`) remains unchanged to avoid storage corruption.
   - Compile and deploy the new `SubscriptionLogicV2` contract.
   - Copy the new contract’s address.

2. **Upgrade the Proxy**:

   - Switch to the admin account in Remix or MetaMask.
   - Call the `upgrade` function on `UpgradeHub` with the new `SubscriptionLogicV2` address as `_newImplementation`.
   - Verify the upgrade:
     - Call `getImplementation` on `UpgradeHub` to confirm it returns the new `SubscriptionLogicV2` address.

3. **Test New Functionality**:
   - Call the `getVersion` function on `UpgradeHub` to verify it returns `"V2"`.
   - Re-test existing functions (e.g., `getSubscription`, `subscribe`) to ensure storage and functionality are intact.

### 7. Verify Storage and Security

- **Storage Consistency**: After the upgrade, call `getSubscription` and `getPlan` to confirm that user subscriptions and plans remain unchanged, ensuring storage layout compatibility.
- **Access Control**:
  - Try calling `addPlan` or `upgrade` from a non-admin account to verify they revert with "Only admin" errors.
  - Try subscribing with insufficient ETH to verify it reverts with "Insufficient payment".
- **ETH Handling**: Check that excess ETH sent during `subscribe` or `upgradePlan` is refunded by monitoring the account balance.

### 8. Troubleshooting Tips

- **Compilation Errors**: Ensure the Solidity version is `0.8.20` or higher.
- **Delegatecall Failures**: If `Delegatecall failed` errors occur, verify the `implementation` address is set correctly in `UpgradeHub`.
- **Storage Corruption**: If data is inconsistent after an upgrade, check that the storage layout in the new `SubscriptionLogic` matches `UpgradeHub`.
- **Gas Issues**: Use a test network or JavaScript VM to avoid real ETH costs. Increase gas limits if transactions fail.

### 9. Best Practices for Production

- **Audit the Contracts**: Before deploying to a mainnet, have the contracts audited for security vulnerabilities.
- **Test Upgrades Extensively**: Simulate multiple upgrades with real-world scenarios to ensure storage alignment.
- **Use a Proxy Admin Contract**: In production, consider using a dedicated proxy admin contract (e.g., OpenZeppelin’s `ProxyAdmin`) for safer upgrades.
- **Backup Storage**: Export subscription data before upgrades as a precaution, even though the proxy pattern avoids data migration.

## Conclusion

By following these steps, you can test the `UpgradeHub` and `SubscriptionLogic` contracts in Remix, verify their functionality, and simulate upgrades. The proxy pattern ensures that subscription data persists across logic upgrades, mimicking real-world SaaS applications. For further assistance, refer to the contract comments or consult Solidity documentation.
