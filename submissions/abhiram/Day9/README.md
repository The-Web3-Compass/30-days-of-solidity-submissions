# Smart Calculator with Controller (Solidity)

This example demonstrates how one smart contract (SmartCalculator) can delegate work to another contract (CalculatorController) using address casting. This is a common pattern in Solidity for modularity and upgradability.

## How it works

- **CalculatorController**: Implements basic math functions (`add`, `sub`, `mul`, `div`).
- **SmartCalculator**: Stores the address of a CalculatorController and calls its functions to perform calculations. It does not do the math itself.
- **Interaction**: SmartCalculator uses the interface `ICalculatorController` and calls the controller's functions using its address. This is called *address casting*.

## Why is this useful?
- Shows how contracts can interact with each other.
- Demonstrates modular design: you can upgrade the controller without changing the calculator.
- Teaches the basics of calling external contracts in Solidity.

## Example Usage
1. Deploy `CalculatorController`.
2. Deploy `SmartCalculator`, passing the address of the deployed `CalculatorController` to its constructor.
3. Call `add`, `sub`, `mul`, or `div` on `SmartCalculator`. It will forward the call to the controller contract.

## Key Solidity Concepts
- **Interfaces**: Used to define the functions available in another contract.
- **Address Casting**: `ICalculatorController(controller).add(a, b)` lets one contract call another's function.
- **External Calls**: Shows how to safely call functions in other contracts.

---

This pattern is foundational for building upgradeable contracts, proxies, and modular dApps.
