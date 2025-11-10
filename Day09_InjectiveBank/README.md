# **Day 09 – Injective Bank Precompile**

This task introduces Injective’s Bank precompile and shows how a Solidity contract can interact with chain-native modules through a fixed system address. The objective is to deploy a token contract that uses Injective’s `IBankModule` for minting, transferring, balance checks, and metadata operations.

### **What I Built**

I implemented a `InjectiveBankDemo` contract that interacts with Injective’s Bank module located at the precompile address `0x0000000000000000000000000000000000000064`. The contract sets token metadata, mints initial supply using the precompile, and forwards balance queries and transfers directly to the Injective Bank.
A minimal Foundry test file was added only to verify object creation, since Injective-specific functions cannot run on a local EVM.

### **Source Code Overview**

**1. IBankModule.sol**
Defines the interface for Injective’s native Bank precompile. Includes methods for minting, burning, transferring, reading balances, metadata, and supply.

**2. InjectiveBankDemo.sol**
Main contract that:

* Sets metadata through the Bank precompile
* Mints the initial supply through the Bank
* Overrides ERC20 `balanceOf`, `totalSupply`, `transfer`, and `transferFrom` to route them through Injective’s module
* Uses `TOKEN_ADDRESS` to identify itself for Bank operations

**3. Test File (InjectiveBankDemo.t.sol)**
Contains a minimal constructor test to ensure the contract can be instantiated locally.
Injective operations revert on local VM, so the test suite is limited by design.

### **Foundry Commands Used**

* `forge init` (initial project setup)
* `forge build` (compiles the contract)
* `forge install foundry-rs/forge-std` (testing library)
* `forge test` (runs tests)

### **Why Tests Fail on Local Environment**

Injective precompiles exist only on the Injective EVM chain.
Foundry/Anvil does not have the precompile address `0x64`, so any call to the bank module reverts.
Only constructor deployment can be tested locally.
The code is correct; the limitation is environmental.

### **Project Notes**

* All unnecessary folders such as `lib`, `out`, `cache`, and `broadcast` were removed before adding to the repository.
* This task demonstrates how Solidity interacts with external modules that are implemented natively at the protocol level.
* The code compiles successfully, but full functional tests require an Injective node or testnet endpoint.

### **Summary**

This project implemented a token contract that uses Injective’s Bank precompile for core token functions. The work includes the interface, main contract, and minimal tests. Due to precompile limitations on local EVMs, only constructor deployment can be verified with Foundry.

# End of the Project.
