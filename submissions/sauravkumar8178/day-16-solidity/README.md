# Day 16 of #30DaysOfSolidity — Modular Profile System for Web3 Games

## 🎯 Introduction

Modern Web3 games need to be **dynamic, scalable, and upgradeable** — just like traditional online games that release new expansions or plug-ins.

This project demonstrates a **modular player profile system** where:

* A **Core Profile Contract** stores each player’s profile.
* Optional **plugin contracts** add extra features such as achievements, inventory, and battle stats.
* The **core contract** uses `delegatecall` to execute plugin logic **without redeploying** the main contract.

This is a **real-world architecture** inspired by protocols like **Lens Protocol**, **Sandbox**, and **TreasureDAO** for long-term scalability.

---

## 🧪 How to Deploy and Run (No Frameworks)

### Step 1: Open Remix IDE

Visit 👉 [https://remix.ethereum.org](https://remix.ethereum.org)

### Step 2: Add Contract Files

Create separate files for the core profile, plugin interface, and example plugin.

### Step 3: Compile Contracts

* Select Solidity compiler **0.8.20** (or newer).
* Compile all files successfully.

### Step 4: Deploy Contracts

1. Deploy the **Core Profile** contract.
2. Deploy the **Achievement Plugin** contract.

Copy both deployed addresses for further steps.

### Step 5: Register Plugin

* Function: `registerPlugin`
* Parameters:

  * `_name`: `"Achievements"`
  * `_plugin`: `<AchievementPlugin Address>`
* Click **Transact**.
  ✅ The Achievements plugin is now registered.

### Step 6: Create a Player Profile

* Use `createProfile` function:

  * `_name`: `"Player1"`
  * `_avatar`: `"ipfs://avatar123"`

### Step 7: Activate Plugin

* Call `activatePlugin`:

  * `_pluginName`: `"Achievements"`

### Step 8: Execute Plugin Logic (Delegatecall)

* Prepare plugin data (for example, `"First Kill"`)
* Execute via `executePlugin` with encoded data.

You should see the event `AchievementUnlocked(player, "First Kill")`.
🎉 Plugin logic executed successfully through `delegatecall` without modifying the core contract.

---

## 🔒 Safe `delegatecall` Usage

`delegatecall` allows plugins to run **in the core contract's storage context**, so safety is essential:

✅ Only **trusted plugin addresses** should be registered.
✅ Use a **fixed storage layout** to avoid data corruption.
✅ Validate plugin execution to prevent arbitrary calls.
✅ Maintain **separate plugin registries** for different modules in production.

This architecture is inspired by **EIP-2535 Diamond Standard**, **Lens Protocol**, and **Sandbox Avatars**.

---

## 🚀 Real-World Applications

* **GameFi Platforms** → Plugin-based avatars and stats.
* **Social Protocols** → Extensible profile features.
* **DAO Tools** → Modular role or reward extensions.
* **Metaverse Worlds** → Upgradable player modules.

---

## 🧠 Key Takeaways

* `delegatecall` enables **modular, upgradable contract systems**.
* Plugins extend functionality **without redeploying** the core contract.
* This design pattern is widely used in **production-level Web3 projects**.

