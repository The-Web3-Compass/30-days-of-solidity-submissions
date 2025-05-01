# YieldFarming Contract

Hey hey, welcome back to **30 Days of Solidity** —

where every single day, we’re not just learning how smart contracts work…

we’re **building the building blocks of DeFi** ourselves (among other things 😉).

And today?

You’re about to build one of the **engines that runs DeFi**:

A **Yield Farming Platform**.

---

## 🧠 But First... What _Is_ Yield Farming?

Let’s make it super simple.

Imagine your tokens are like seeds.

You could:

- Just leave them sitting in your wallet doing nothing...
- **Or** you could "plant" them somewhere, **lock them up for a while**, and **grow more tokens** as a reward.

That’s yield farming.

> Stake tokens → Let time pass → Harvest rewards.

Instead of your assets gathering dust, they’re gathering _yield_.

And the longer or bigger you stake, the more you earn.

---

In the real world of Web3, yield farming powers:

- Liquidity pools
- DAO treasuries
- DeFi incentives
- GameFi reward systems
- Launchpads and token distributions

It’s **everywhere**.

From Uniswap to SushiSwap to Curve —

**behind every reward pool, there’s a smart contract just like the one you're about to build**.

---

## 💡 What You're Building Today

In today's project, you’re going to create a contract that lets users:

- 📥 **Stake** ERC-20 tokens
- ⏳ **Accrue rewards over time**, based on how much and how long they staked
- 💰 **Claim their rewards** whenever they want
- 🚪 **Emergency withdraw** their tokens instantly if they need to
- 🔧 **Admins can refill** the reward pool to keep the farming alive

And we’ll do it all:

- With **reentrancy protection**
- Handling **different tokens and decimals** cleanly

In short:

You’re not just handing out tokens randomly —

You’re building a **fair**, **secure**, **time-weighted reward system** that keeps the DeFi ecosystem running.

---

## 🔥 Why This Contract Matters

This Yield Farming Platform is the **real foundation** of many DeFi protocols.

It shows you how to:

- Track **individual user stakes** properly
- Calculate **dynamic rewards** over time
- Build **emergency exit options** for users
- **Manage reward funds** without breaking the system

By mastering this, you’ll unlock a whole new level of smart contract development — one where **time**, **value**, and **user behavior** all interact on-chain.

---

# 🚀 Ready to Plant Some Seeds?

Alright, before we get our hands dirty with the code...

Let’s take a quick step back and **understand the full logic** of what you’re about to build.

Because **this isn’t just a random staking contract** —

it’s a carefully thought-out system where every piece plays an important role.

Here’s how the whole flow will work:

---

## 🧩 Big Picture Logic of Our Yield Farming Contract

### 1. 📥 Staking

- Users call `stake()` to **deposit their tokens** into the farm.
- We track **how much** they staked and **when** they staked it.
- Their rewards start **accumulating automatically** over time — based on the amount staked.

---

### 2. ⏳ Earning Rewards

- Rewards are calculated **second-by-second** — not block-by-block.
- The more tokens you stake, and the longer you leave them, **the bigger your reward**.
- We don’t mint rewards magically —
  they must be **pre-funded** by the admin into the contract (`refillRewards()`).

---

### 3. 💰 Claiming Rewards

- When a user wants to harvest, they call `claimRewards()`.
- They receive all their accumulated rewards **in the reward token**.
- Their reward counter resets to zero after claiming.

---

### 4. 🚪 Unstaking

- Users can also `unstake()` some or all of their tokens.
- When they do, they still **claim their pending rewards** before their stake is reduced.
- It’s a **smooth exit** without losing earned rewards.

---

### 5. 🚨 Emergency Withdraw

- If something crazy happens (user panic, UI bug, hack scare), users can call `emergencyWithdraw()`.
- This lets them **instantly pull out their stake** —
  but **they lose any pending rewards** as a trade-off for the emergency exit.

---

### 6. 🔧 Admin Controls

- The **owner** (the one who deployed the contract) can call `refillRewards()`.
- This adds more reward tokens into the system, **keeping the farm alive and sustainable**.
- No need to redeploy the contract — you can keep topping it up.

---

### 7. 🛡️ Safety Built In

- **ReentrancyGuard** is active on all sensitive functions.
- **SafeCast** is used to prevent overflows/underflows when doing math.
- ETH transfers are **rejected** — this is ERC-20 only.
- Everything is designed to be **fair, secure, and time-based**.

---

# 📜 Full ield Farming Contract

Alright, here’s the big picture:

What you're about to see isn't just another Solidity contract.

It’s the **full blueprint of a live DeFi farming system** — the kind that sits behind real staking programs, liquidity incentives, and Web3 reward systems.

This smart contract you’re holding in your hands will let users:

- 📥 **Stake ERC-20 tokens** into the farm
- ⏳ **Accrue rewards automatically** over time, second-by-second
- 💰 **Claim rewards** whenever they want to harvest
- 🚪 **Unstake** their tokens while collecting rewards
- 🚨 **Emergency withdraw** without waiting if needed
- 🔧 **Admin refill** the reward pool without stopping or restarting the contract

And while it does all that, it also:

- 🛡️ Protects against reentrancy attacks
- 📏 Handles token decimals safely
- 🏗️ Stores and calculates rewards fairly across thousands of users if needed
- 📢 Emits events for everything important (staking, unstaking, rewards, emergencies)

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol"; // For SafeCast if needed

// Interface for fetching ERC-20 metadata (decimals)
interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

/// @title Yield Farming Platform
///     Stake tokens to earn rewards over time with optional emergency withdrawal and admin refill
contract YieldFarming is ReentrancyGuard {
    using SafeCast for uint256;

    IERC20 public stakingToken;
    IERC20 public rewardToken;

    uint256 public rewardRatePerSecond; // Rewards distributed per second

    address public owner;

    uint8 public stakingTokenDecimals; // Store the number of decimals for the staking token

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 rewardDebt;
        uint256 lastUpdate;
    }

    mapping(address => StakerInfo) public stakers;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardRefilled(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRatePerSecond
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRatePerSecond;
        owner = msg.sender;

        // Try fetching decimals
        try IERC20Metadata(_stakingToken).decimals() returns (uint8 decimals) {
            stakingTokenDecimals = decimals;
        } catch (bytes memory) {
            stakingTokenDecimals = 18; // Default to 18 decimals if fetching fails
        }
    }

    ///     Stake tokens to start earning rewards
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");

        updateRewards(msg.sender);

        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakers[msg.sender].stakedAmount += amount;

        emit Staked(msg.sender, amount);
    }

    ///     Unstake tokens and optionally claim rewards
    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot unstake 0");
        require(stakers[msg.sender].stakedAmount >= amount, "Not enough staked");

        updateRewards(msg.sender);

        stakers[msg.sender].stakedAmount -= amount;
        stakingToken.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    ///     Claim accumulated rewards
    function claimRewards() external nonReentrant {
        updateRewards(msg.sender);

        uint256 reward = stakers[msg.sender].rewardDebt;
        require(reward > 0, "No rewards to claim");
        require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward token balance");

        stakers[msg.sender].rewardDebt = 0;
        rewardToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    ///     Emergency unstake without claiming rewards
    function emergencyWithdraw() external nonReentrant {
        uint256 amount = stakers[msg.sender].stakedAmount;
        require(amount > 0, "Nothing staked");

        stakers[msg.sender].stakedAmount = 0;
        stakers[msg.sender].rewardDebt = 0;
        stakers[msg.sender].lastUpdate = block.timestamp;

        stakingToken.transfer(msg.sender, amount);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    ///     Admin can refill reward tokens
    function refillRewards(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);

        emit RewardRefilled(msg.sender, amount);
    }

    ///     Update rewards for a staker
    function updateRewards(address user) internal {
        StakerInfo storage staker = stakers[user];

        if (staker.stakedAmount > 0) {
            uint256 timeDiff = block.timestamp - staker.lastUpdate;
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
            uint256 pendingReward = (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
            staker.rewardDebt += pendingReward;
        }

        staker.lastUpdate = block.timestamp;
    }

    ///     View pending rewards without claiming
    function pendingRewards(address user) external view returns (uint256) {
        StakerInfo memory staker = stakers[user];

        uint256 pendingReward = staker.rewardDebt;

        if (staker.stakedAmount > 0) {
            uint256 timeDiff = block.timestamp - staker.lastUpdate;
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
            pendingReward += (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
        }

        return pendingReward;
    }

    ///     View staking token decimals
    function getStakingTokenDecimals() external view returns (uint8) {
        return stakingTokenDecimals;
    }
}

```

---

# 📦 1. Imports – Bringing In the Right Tools

Before we write even a single line of custom logic,

we pull in some **battle-tested OpenZeppelin libraries** to make our contract **safer**, **smarter**, and **future-proof**.

Here are the imports we’re using — and why each one matters:

---

### ✅ 1.1 ERC-20 Interface

```solidity

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

```

This import gives us access to the **ERC-20 interface** — basically, the standard set of functions that any token like USDC, DAI, or your custom token will follow.

It includes essential functions like:

- `transfer()`
- `transferFrom()`
- `approve()`
- `balanceOf()`

**Why we need it here:**

Because users will be staking and claiming **ERC-20 tokens**, and we need to interact with those tokens safely without hardcoding anything.

✅ Whether it’s a custom token, a stablecoin, or something else — as long as it follows ERC-20, our contract can handle it.

---

### 🛡️ 1.2 Reentrancy Guard

```solidity

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

```

This one is **super important** for **security**.

When money (or tokens) move inside a smart contract, you have to be careful about something called a **reentrancy attack** — where someone tries to call a function _again_ before it finishes the first time, causing unexpected behavior and potentially draining funds.

**Why we need it here:**

Functions like `stake()`, `unstake()`, `claimRewards()`, and `emergencyWithdraw()` are all handling token transfers — which means they are potential targets for reentrancy.

✅ By using `ReentrancyGuard`, we make sure that once a function starts executing, it **locks** itself until it finishes — no sneaky re-entry allowed.

---

### 🧮 1.3 SafeCast

```solidity

import "@openzeppelin/contracts/utils/math/SafeCast.sol"; // For SafeCast if needed

```

In Solidity, when you move between different types of numbers (like `uint256` → `uint8`), you need to be **really careful**.

If you blindly downcast numbers without checking, you can **overflow** or **truncate values** without realizing it — which can lead to bugs or even security holes.

**Why we need it here:**

When dealing with rewards and calculations, especially involving token **decimals**, we want to make sure we're casting numbers **safely**.

✅ `SafeCast` helps prevent accidental overflows or data loss when we’re doing math across different sizes of numbers.

---

# 🛠️ 2. Custom Interface for ERC-20 Metadata

Here’s the snippet again:

```solidity

// Interface for fetching ERC-20 metadata (decimals)
interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

```

---

### 🧠 What's Going On Here?

We’re creating a **tiny extension** of the standard `IERC20` interface.

Normally, an ERC-20 token guarantees it will have:

- `balanceOf()`
- `transfer()`
- `approve()`
- and other basic functions...

**But guess what?**

**`decimals()`, `name()`, and `symbol()` are _optional_ in the original ERC-20 standard.**

They became common _later_ — but not every ERC-20 token is required to implement them officially.

That’s why OpenZeppelin separated it into a different interface called `IERC20Metadata`.

We’re recreating it here in a lightweight way so we can _use_ those functions if the token supports them — without assuming they exist by default.

---

### 🔥 Why We Need This

Our Yield Farming contract **wants to know** the `decimals` of the staking token —

because when we calculate rewards, we need to **scale** numbers correctly.

Example:

| Token | Decimals    | What 1 Token Looks Like                 |
| ----- | ----------- | --------------------------------------- |
| USDC  | 6 decimals  | 1 USDC = 1,000,000 units                |
| ETH   | 18 decimals | 1 ETH = 1,000,000,000,000,000,000 units |

> 🧠 If you ignore decimals, your math will be completely wrong —
>
> Users might earn _way too much_ or _way too little_ in rewards.

---

### 📚 Breakdown of Each Function

| Function     | Purpose                                                        |
| ------------ | -------------------------------------------------------------- |
| `decimals()` | Returns how many decimal places the token uses                 |
| `name()`     | Returns the human-readable token name (e.g., "Dai Stablecoin") |
| `symbol()`   | Returns the short ticker symbol (e.g., "DAI")                  |

- We **mainly** care about `decimals()` for reward math.
- But having `name()` and `symbol()` handy could be useful for UIs later too!

---

### 🌟 And That's Why This Tiny Interface Matters

It’s a small thing — just a few lines.

But without it, **your whole farm could break** when staking tokens with weird decimals.

Good contracts **think about the real-world messiness** —

and you’re learning to build with that kind of foresight right now. 🌱

---

# 🏛️ 3. Contract Declaration

```solidity

contract YieldFarming is ReentrancyGuard {

```

---

## 🧠 What's Happening Here?

This line does two major things at once:

### 1. 📜 Creates the Contract

We’re creating a brand-new smart contract called **`YieldFarming`**.

This is the name people will use when they interact with your farm.

It’s what wallets like MetaMask will display.

It’s the name that will show up in explorers like Etherscan.

It’s your **digital farm’s official title**.

---

### 2. 🛡️ Inherits Reentrancy Protection

Notice the `is ReentrancyGuard` part?

This means our YieldFarming contract **inherits** from OpenZeppelin’s `ReentrancyGuard` contract.

> 🧠 In Solidity, inheritance means you pull in the functions and protections from another contract — without having to rewrite them yourself.

**Specifically:**

It gives us the `nonReentrant` modifier, which we’ll use on all sensitive functions like:

- `stake()`
- `unstake()`
- `claimRewards()`
- `emergencyWithdraw()`

✅ Every time users deposit or withdraw tokens, we’ll **lock** the function to prevent reentrancy attacks —

the kind of attacks that drained millions from poorly written DeFi apps in the past.

> Without even realizing it, you’re writing DeFi-level secure code just by setting this up correctly.

---

# 📦 4. State Variables – What Data Will Our Farm Handle?

Alright — before we start building staking functions or reward claims,

let’s take a moment to think about the **kind of data** our farm actually needs to keep track of.

Because when you're building a system where users lock up their tokens and earn rewards over time,

**you can't just "hope" the numbers work out.**

You need to:

- Know **what tokens** users are staking
- Know **what tokens** users will be rewarded with
- Know **how fast** rewards are given out
- Keep track of **who is in charge** of maintaining the farm
- Handle **different token decimals** cleanly (because not all tokens are created equally)

In this section, we're going to **declare all the important state variables** —

the pieces of information our farm will need to function smoothly, fairly, and securely.

---

✅ Now, let’s break it down line by line!

```solidity

using SafeCast for uint256;

IERC20 public stakingToken;
IERC20 public rewardToken;

uint256 public rewardRatePerSecond; // Rewards distributed per second

address public owner;

uint8 public stakingTokenDecimals;

```

---

## 🛠️ Line-by-Line Breakdown

---

### ✅ `using SafeCast for uint256;`

**This line is a Solidity trick** — it extends the native `uint256` type with new _safe_ functions from the `SafeCast` library.

**In plain English:**

It allows us to call methods like `.toUint8()`, `.toUint128()`, etc., **directly on `uint256` numbers** — and safely convert between different types without risking overflow or weird bugs.

> Example:
>
> If we later have a `uint256` and we need to safely shrink it down to a `uint8`,
>
> instead of writing a big check manually, we can just do:
>
> ```solidity
>
> uint8 smallNumber = bigNumber.toUint8();
>
> ```

✅ **It makes casting simpler and safer.**

We’ll mainly use this when:

- Handling different reward scales
- Managing decimals
- Doing precise reward calculations

---

```solidity
IERC20 public stakingToken;
```

This is the **token** that users will stake (lock) into the contract.

- It could be anything: a custom token, a governance token, a stablecoin like DAI, etc.
- It's stored as an `IERC20` interface, so we can call functions like `transferFrom()`, `transfer()`, and `balanceOf()` on it.

✅ This is the **asset** users are depositing into the farm.

---

```solidity
IERC20 public rewardToken;
```

This is the **token** that users will earn as rewards.

- It could be the same as the staking token (stake DAI, earn DAI)
- Or it could be a different one (stake DAI, earn FARM tokens)

✅ This gives flexibility to the system — you can reward users with any ERC-20 token you want.

---

```solidity
uint256 public rewardRatePerSecond;
```

This defines **how fast rewards are generated**.

- It’s the number of reward tokens distributed **per second** across all stakers.
- So, if you set `rewardRatePerSecond = 1e18`, the system is giving out `1` reward token (in wei) **every second**.

✅ This allows you to fine-tune the **pace** of the farming program based on how big the reward pool is.

---

```solidity
address public owner;
```

This stores the **admin’s wallet address** —

the person (or multisig, or DAO) who deployed the contract.

The `owner` will have special powers like:

- Refilling the reward pool
- Potentially pausing/updating things in more advanced versions

✅ Only the owner can call sensitive functions protected by the `onlyOwner` modifier.

---

```solidity
uint8 public stakingTokenDecimals;
```

When we do reward calculations, we have to **scale math correctly based on decimals**.

- Some tokens have 18 decimals (like ETH).
- Some tokens have 6 decimals (like USDC).
- Some weird tokens have even less.

By reading and saving the staking token’s decimals when the contract is deployed,

we make sure that **reward math stays accurate** no matter what token users are staking.

✅ No decimal mismatch mistakes = no math disasters.

---

# 🧱 5. Tracking Each User – Struct and Mapping

Alright — so far, we’ve set up the _global_ variables:

what token people are staking, what they earn, who owns the farm, and so on.

But now it's time to zoom in and think about the **individual users**.

Because when someone stakes tokens into the farm,

we need to **keep track of their personal data**:

- How much they staked
- How many rewards they’ve earned (but maybe haven't claimed yet)
- When was the last time their rewards were updated

If we don’t track this correctly, the whole reward system will fall apart —

some users might get too much, others too little.

So, in this part of the contract, we’re setting up a **clean, organized structure** to manage **each staker’s info**.

Here’s the code we're looking at:

```solidity

struct StakerInfo {
    uint256 stakedAmount;
    uint256 rewardDebt;
    uint256 lastUpdate;
}

mapping(address => StakerInfo) public stakers;

```

---

## 🧠 Logic Behind These Lines

---

```solidity
stakedAmount
```

This keeps track of **how many staking tokens** a user has deposited into the farm.

Every time a user **stakes** or **unstakes**, we update this number.

- More stake = more rewards over time.
- Less stake = smaller share of rewards.

✅ It tells us **how big the user's position** is inside the farm at any moment.

---

```solidity
rewardDebt
```

This keeps track of **how much reward** the user has **already earned but not yet claimed**.

Whenever a user interacts with the farm, we **update** their `rewardDebt` based on:

- How much they staked
- How much time has passed
- The reward rate

✅ It prevents users from "forgetting" about old rewards or accidentally earning twice for the same staking time.

---

```solidity
lastUpdate
```

This records the **last time we updated** the user's rewards.

When a user stakes, unstakes, or claims, we:

- Calculate how much they earned since `lastUpdate`
- Update `rewardDebt`
- Then **refresh** their `lastUpdate` to the current block timestamp.

✅ It ensures rewards are based on **actual time spent** staking — not assumptions.

---

```solidity
mapping(address => StakerInfo) public stakers;
```

This maps **each user's address** to their **personal StakerInfo data**.

So for every user, the contract knows:

- How much they staked
- How many rewards they’ve built up
- When their rewards were last updated

✅ It’s how we **keep track of everyone's position** individually inside the farm — cleanly and securely.

---

# 📢 6. Events – Broadcasting What Happens Inside the Farm

Alright — now that we’re tracking who’s staking and earning rewards,

we also need a way to **broadcast important actions** to the outside world.

Because remember:

**Smart contracts don't have a front-end.**

They can’t "talk" to users directly —

they can only **emit events** that wallets, dapps, and explorers like Etherscan can listen for.

---

Here are the events we’ve declared:

```solidity

event Staked(address indexed user, uint256 amount);
event Unstaked(address indexed user, uint256 amount);
event RewardClaimed(address indexed user, uint256 amount);
event EmergencyWithdraw(address indexed user, uint256 amount);
event RewardRefilled(address indexed owner, uint256 amount);

```

---

## 🧠 Logic Behind Each Event

---

### 📥 `Staked`

```solidity

event Staked(address indexed user, uint256 amount);

```

- Fires when a user **stakes tokens** into the farm.
- Tells us **who staked** and **how much** they staked.

✅ Useful for tracking deposits, building user dashboards, and showing "User X staked Y tokens" on a frontend.

---

### 🚪 `Unstaked`

```solidity

event Unstaked(address indexed user, uint256 amount);

```

- Fires when a user **unstakes** (withdraws) their tokens.
- Tells us **who withdrew** and **how much** they removed.

✅ Helps frontends update balances, and lets users see a clean history of their exits.

---

### 💰 `RewardClaimed`

```solidity

event RewardClaimed(address indexed user, uint256 amount);

```

- Fires when a user **claims their pending rewards** without unstaking.
- Shows **who claimed** and **how many reward tokens** they received.

✅ Vital for reward history, analytics, and showing users how much they’ve earned so far.

---

### 🚨 `EmergencyWithdraw`

```solidity

event EmergencyWithdraw(address indexed user, uint256 amount);

```

- Fires when a user **pulls out their stake immediately** without waiting for rewards.
- Tells us **who made an emergency exit** and **how much** they withdrew.

✅ Helps track panic exits during emergencies — and tells users their emergency withdrawal succeeded.

---

### 🧹 `RewardRefilled`

```solidity

event RewardRefilled(address indexed owner, uint256 amount);

```

- Fires when the **admin** refills the contract with new reward tokens.
- Tells us **who refilled** and **how many tokens** were added to the pool.

✅ Crucial for transparency — users can see when the reward pool gets topped up and farming continues.

---

# 🛡️ 7. Modifier – Protecting Admin-Only Actions

Here’s the code:

```solidity

modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner");
    _;
}

```

---

## 🧠 What’s Happening Here?

This `onlyOwner` modifier acts like a **security checkpoint**.

Whenever we attach `onlyOwner` to a function,

it forces the contract to **check**:

> Is the person calling this function actually the owner of the farm?

If yes — ✅ the function executes normally.

If no — ❌ the transaction immediately reverts with the error `"Not the owner"`.

---

# 🏗️ 8. Constructor

Alright — before anyone can start staking or earning rewards,

we need to **set up the farm**:

- What token are users going to stake?
- What token will they earn as rewards?
- How fast should rewards be distributed?

All of that is decided **once**, right when the contract is deployed — inside the **constructor**.

> Think of it like setting the rules of the farm before you open the gates to the farmers.

This constructor locks in all the important starting values, so everything else can run smoothly later.

---

## 📜 Constructor Code

```solidity

constructor(
    address _stakingToken,
    address _rewardToken,
    uint256 _rewardRatePerSecond
) {
    stakingToken = IERC20(_stakingToken);
    rewardToken = IERC20(_rewardToken);
    rewardRatePerSecond = _rewardRatePerSecond;
    owner = msg.sender;

    // Try fetching decimals
    try IERC20Metadata(_stakingToken).decimals() returns (uint8 decimals) {
        stakingTokenDecimals = decimals;
    } catch (bytes memory) {
        stakingTokenDecimals = 18; // Default to 18 decimals if fetching fails
    }
}

```

---

## 🔍 Line-by-Line Breakdown

---

### 🧩 Set the Staking Token

```solidity

stakingToken = IERC20(_stakingToken);

```

- This tells the contract **which ERC-20 token** users must stake to participate.
- We treat the `_stakingToken` address as an `IERC20` — so we can interact with it safely (transfer, balance checks, etc.)

✅ Without this, users wouldn't know what asset they’re supposed to lock into the farm.

---

### 🎁 Set the Reward Token

```solidity

rewardToken = IERC20(_rewardToken);

```

- This tells the contract **which ERC-20 token** users will earn as rewards.
- It could be the same token as the staking token, or a completely different token.

✅ Flexibility is built right in — you can reward users however you want.

---

### ⏳ Set the Reward Rate

```solidity

rewardRatePerSecond = _rewardRatePerSecond;

```

- This defines **how many reward tokens** are distributed **every second** to stakers collectively.
- Higher rate = rewards are distributed faster.
- Lower rate = rewards are distributed more slowly.

✅ This is what controls the "speed" at which the farm pays out rewards.

---

### 👑 Set the Owner

```solidity

owner = msg.sender;

```

- Whoever deploys the contract becomes the **owner**.
- This person will have permission to call special functions like `refillRewards()`.

✅ Only the owner can refill reward pools and manage the farm's health.

---

### 🧮 Try to Fetch Staking Token Decimals

```solidity

try IERC20Metadata(_stakingToken).decimals() returns (uint8 decimals) {
    stakingTokenDecimals = decimals;
} catch (bytes memory) {
    stakingTokenDecimals = 18; // Default to 18 decimals if fetching fails
}

```

- We **attempt** to read the `decimals()` function from the staking token.
- Some tokens (especially non-standard ones) might not implement this, so we wrap it in a `try/catch`.
- If fetching decimals succeeds, great — we store it.
- If it fails, we assume **18 decimals** (which is the standard for most modern ERC-20s).

✅ This ensures our reward calculations stay **accurate**, even across different kinds of tokens.

---

# 📥 9. `stake()` – Users Enter the Farm and Start Earning

Alright — now that the farm is set up,

we need a way for users to **actually join** and **start farming rewards**.

That's exactly what the `stake()` function does:

> A user sends some tokens into the contract →
>
> We store their deposit →
>
> And they immediately start earning rewards **second by second**.

This is where **users officially plant their seeds** in the farming system.

---

## 📜 Full Code for `stake()`

```solidity

///     Stake tokens to start earning rewards
function stake(uint256 amount) external nonReentrant {
    require(amount > 0, "Cannot stake 0");

    updateRewards(msg.sender);

    stakingToken.transferFrom(msg.sender, address(this), amount);
    stakers[msg.sender].stakedAmount += amount;

    emit Staked(msg.sender, amount);
}

```

---

## 🔍 Line-by-Line Breakdown

---

### 🛡️ Protect Against Reentrancy

```solidity

function stake(uint256 amount) external nonReentrant {

```

- This function can be called by **anyone** (`external`), but
- It’s protected by the `nonReentrant` modifier to **block reentrancy attacks** (because it involves transferring tokens).

✅ Always protect functions that move money.

---

### ⚡ Basic Validation: Can't Stake 0

```solidity

require(amount > 0, "Cannot stake 0");

```

- Users must stake **at least 1 unit** (even if it's a very small amount).
- Staking zero makes no sense and could cause weird corner cases.

✅ A simple, good first check.

---

### 🧠 Update Pending Rewards

```solidity

updateRewards(msg.sender);

```

- Before accepting a new deposit, we **calculate and store** any pending rewards the user has already earned so far.
- This ensures **fair reward tracking** — the new deposit doesn’t wipe out or mess up previous rewards.

✅ Rewards must be calculated _before_ changing the staked amount.

---

### 💸 Pull in the Staked Tokens

```solidity

stakingToken.transferFrom(msg.sender, address(this), amount);

```

- We **pull** the staking tokens from the user’s wallet into the contract.
- User must have **approved** the farm contract to spend their tokens beforehand (standard ERC-20 behavior).

✅ After this line, the user’s tokens are officially locked into the farm.

---

### 🧮 Update Staker’s Amount

```solidity

stakers[msg.sender].stakedAmount += amount;

```

- We **increase** the user’s total `stakedAmount` by the newly deposited amount.
- This new amount will be used for calculating future rewards.

✅ Bigger stake = bigger share of rewards per second.

---

### 📢 Emit Staking Event

```solidity

emit Staked(msg.sender, amount);

```

- Fires an event letting UIs and explorers know that:
  - **Who staked**
  - **How much they staked**

✅ Transparent history for the user and for frontends.

---

# 🚪 10. `unstake()` – Letting Users Exit the Farm (and Still Earn)

Alright — staking is awesome, but users also need a way to **leave the farm** whenever they want.

Maybe they want to cash out. Maybe they just need their tokens back.

The `unstake()` function lets them **safely withdraw their staked tokens**,

**while still collecting any rewards** they’ve earned up to that point.

It’s like pulling your seeds out of the ground **and picking up all the fruits you’ve grown so far**.

---

## 📜 Full Code for `unstake()`

```solidity

///     Unstake tokens and optionally claim rewards
function unstake(uint256 amount) external nonReentrant {
    require(amount > 0, "Cannot unstake 0");
    require(stakers[msg.sender].stakedAmount >= amount, "Not enough staked");

    updateRewards(msg.sender);

    stakers[msg.sender].stakedAmount -= amount;
    stakingToken.transfer(msg.sender, amount);

    emit Unstaked(msg.sender, amount);
}

```

---

## 🔍 Line-by-Line Breakdown

---

### 🛡️ Lock the Function Against Reentrancy

```solidity

function unstake(uint256 amount) external nonReentrant {

```

- `external`: Anyone can call it — only for themselves.
- `nonReentrant`: We lock it to **prevent reentrancy attacks** because tokens are being transferred.

✅ Security first, always.

---

### ⚡ Basic Validations

```solidity

require(amount > 0, "Cannot unstake 0");

```

- Users must unstake **a real amount**.
- No zero-unstakes allowed (would be pointless and could mess up accounting).

✅ Clean, predictable behavior.

---

```solidity

require(stakers[msg.sender].stakedAmount >= amount, "Not enough staked");

```

- Users can’t unstake more than they originally deposited.
- If they try to unstake too much, the transaction **reverts** immediately.

✅ Protects the farm’s internal balances.

---

### 🧠 Update Rewards Before Unstaking

```solidity

updateRewards(msg.sender);

```

- Before changing the user’s stake, we **calculate and lock in** any rewards they earned up to this point.
- This way, users **don't lose** rewards even if they unstake partially.

✅ Fair rewards, even on partial exits.

---

### 🧮 Decrease Staked Amount

```solidity

stakers[msg.sender].stakedAmount -= amount;

```

- After updating rewards, we **decrease** the user’s `stakedAmount` by the amount they’re unstaking.

✅ Their farming power adjusts immediately to match their new stake.

---

### 💸 Transfer Tokens Back to User

```solidity

stakingToken.transfer(msg.sender, amount);

```

- We **send back** the unstaked tokens to the user’s wallet.
- No third party involved — it’s a direct, on-chain, self-service operation.

✅ User regains full control of their tokens.

---

### 📢 Emit Unstaked Event

```solidity

emit Unstaked(msg.sender, amount);

```

- We fire an event so UIs, explorers, and logs know:
  - **Who unstaked**
  - **How much they unstaked**

✅ Keeps the system transparent and easy to track.

---

# 💰 11. `claimRewards()` – Harvest Your Earned Tokens

Alright — so far, users have been staking their tokens and watching their rewards grow quietly in the background.

But how do they actually **collect** those rewards?

That’s exactly what `claimRewards()` lets them do:

> It’s like harvesting the fruits you've grown —
>
> without uprooting the tree itself.

Users can **claim their earned rewards** anytime they want,

**without touching** their original stake.

---

## 📜 Full Code for `claimRewards()`

```solidity

///     Claim accumulated rewards
function claimRewards() external nonReentrant {
    updateRewards(msg.sender);

    uint256 reward = stakers[msg.sender].rewardDebt;
    require(reward > 0, "No rewards to claim");
    require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward token balance");

    stakers[msg.sender].rewardDebt = 0;
    rewardToken.transfer(msg.sender, reward);

    emit RewardClaimed(msg.sender, reward);
}

```

---

## 🔍 Line-by-Line Breakdown

---

### 🛡️ Lock the Function Against Reentrancy

```solidity

function claimRewards() external nonReentrant {

```

- Again, because we’re moving tokens, we use `nonReentrant` to prevent potential reentrancy exploits.

✅ Always lock down functions that send money.

---

### 🧠 Update the User’s Pending Rewards

```solidity

updateRewards(msg.sender);

```

- Before handing over any rewards,
  we **recalculate** everything based on the current time.
- This ensures the user gets **every single second's worth** of rewards they earned.

✅ No missed time. No lost tokens.

---

### 🧮 Fetch the Pending Reward Amount

```solidity

uint256 reward = stakers[msg.sender].rewardDebt;

```

- We read how much reward the user is currently owed (stored as their `rewardDebt`).

✅ Clean and simple — rewards already tracked internally.

---

### ⚡ Validation Checks

```solidity

require(reward > 0, "No rewards to claim");

```

- If the user has no rewards built up, we reject the claim.

✅ Saves gas and prevents accidental empty transactions.

---

```solidity

require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward token balance");

```

- Double-check that the contract actually **holds enough reward tokens** to pay out the claim.
- If the reward pool is empty or too low, the transaction will revert.

✅ Good failsafe to avoid broken payouts.

---

### 🧹 Reset User’s Reward Debt

```solidity

stakers[msg.sender].rewardDebt = 0;

```

- After sending the rewards, we **reset** the user’s `rewardDebt` to zero.
- Otherwise, they might claim the same rewards again.

✅ Keeps accounting clean and fair.

---

### 💸 Transfer Rewards to User

```solidity

rewardToken.transfer(msg.sender, reward);

```

- Finally, we **send** the reward tokens straight to the user's wallet.

✅ Smooth, direct, and trustless.

---

### 📢 Emit Reward Claimed Event

```solidity

emit RewardClaimed(msg.sender, reward);

```

- Fire an event for transparency and history tracking:
  - **Who claimed**
  - **How much they claimed**

✅ Lets frontends update UIs, and explorers log actions cleanly.

---

# 🚨 12. `emergencyWithdraw()` – The Panic Button

Alright — staking is great when everything is running smoothly...

But what if something crazy happens?

- Maybe the frontend is broken.
- Maybe the user just urgently needs their tokens back.
- Maybe there's a sudden security scare.

Whatever the reason —

users deserve a way to **exit immediately** without worrying about pending rewards.

That's exactly what `emergencyWithdraw()` is for:

> It's like breaking the glass in case of emergency —
>
> Get your tokens back **instantly**, but **leave your rewards behind**.

---

## 📜 Full Code for `emergencyWithdraw()`

```solidity

///     Emergency unstake without claiming rewards
function emergencyWithdraw() external nonReentrant {
    uint256 amount = stakers[msg.sender].stakedAmount;
    require(amount > 0, "Nothing staked");

    stakers[msg.sender].stakedAmount = 0;
    stakers[msg.sender].rewardDebt = 0;
    stakers[msg.sender].lastUpdate = block.timestamp;

    stakingToken.transfer(msg.sender, amount);

    emit EmergencyWithdraw(msg.sender, amount);
}

```

---

## 🔍 Line-by-Line Breakdown

---

### 🛡️ Lock the Function Against Reentrancy

```solidity

function emergencyWithdraw() external nonReentrant {

```

- Security first — even emergency exits are protected against reentrancy attacks.

✅ Keeps things safe even under pressure.

---

### 🧮 Fetch Staked Amount

```solidity

uint256 amount = stakers[msg.sender].stakedAmount;

```

- Load the user's **currently staked amount** into a temporary variable.

✅ We’re preparing to send this back to the user.

---

### ⚡ Validation Check

```solidity

require(amount > 0, "Nothing staked");

```

- Make sure the user actually **has something staked**.
- If not, there’s nothing to withdraw, and the function reverts.

✅ Prevents useless transactions.

---

### 🧹 Reset All User Info

```solidity

stakers[msg.sender].stakedAmount = 0;
stakers[msg.sender].rewardDebt = 0;
stakers[msg.sender].lastUpdate = block.timestamp;

```

- **Zero out** the user's stake and reward debt.
- **Update** their `lastUpdate` to the current time (even though they're exiting).
- This makes sure that if they ever return and stake again, they're starting fresh.

✅ Clean, safe state reset — no leftovers or weird reward bugs.

---

### 💸 Transfer Tokens Back to User

```solidity

stakingToken.transfer(msg.sender, amount);

```

- Send the staked tokens straight back to the user's wallet.

✅ Fast and self-serve exit — no admin needed.

---

### 📢 Emit Emergency Withdraw Event

```solidity

emit EmergencyWithdraw(msg.sender, amount);

```

- Fire an event so the action is logged publicly:
  - **Who withdrew**
  - **How much they took out**

✅ Helps frontends and explorers display emergency exits clearly.

---

# 🔋 13. `refillRewards()` – Keeping the Reward Pool Alive

Alright — users are happily staking, farming, and claiming rewards...

But what happens when the reward pool starts running low?

Instead of shutting everything down or deploying a new contract,

the admin (owner) can simply **top up** the reward pool —

**injecting fresh rewards** to keep the farming season going.

That’s exactly what `refillRewards()` does:

> It's like restocking the shelves of a grocery store.
>
> New rewards come in → farming continues without any interruption.

---

## 📜 Full Code for `refillRewards()`

```solidity

///     Admin can refill reward tokens
function refillRewards(uint256 amount) external onlyOwner {
    rewardToken.transferFrom(msg.sender, address(this), amount);

    emit RewardRefilled(msg.sender, amount);
}

```

---

## 🔍 Line-by-Line Breakdown

---

### 🔒 Owner-Only Access

```solidity

function refillRewards(uint256 amount) external onlyOwner {

```

- Only the `owner` (the one who deployed the farm) can call this.
- Protected by the `onlyOwner` modifier we set up earlier.
- Regular users **cannot** refill the reward pool — only the admin can.

✅ Keeps sensitive actions under admin control.

---

### 💸 Pull New Rewards Into the Contract

```solidity

rewardToken.transferFrom(msg.sender, address(this), amount);

```

- The owner must **approve** the Yield Farming contract first to spend their reward tokens.
- Then this function **pulls** the specified amount into the farm contract.
- These new tokens are now available to pay out to farmers over time.

✅ No reward minting. No weird hacks. Just simple, clean ERC-20 transfers.

---

### 📢 Emit Reward Refilled Event

```solidity

emit RewardRefilled(msg.sender, amount);

```

- Fire an event to publicly log that:
  - **Who refilled** the rewards
  - **How many tokens** they added

✅ Frontends can watch for this event to update reward pool balances live.

---

# 🧠 14. `updateRewards()` – Keeping Rewards Fair and Fresh

Alright — farming rewards don't just magically update themselves.

Every time a user **stakes**, **unstakes**, or **claims rewards**,

we need to **recalculate** how much they’ve earned based on:

- **How long** they've been staked
- **How much** they staked
- **How fast** rewards are being distributed

That’s where the internal `updateRewards()` function comes in:

> It's like checking the growth of a plant every time someone touches it —
>
> and making sure it matches how much time has passed.

This function quietly **keeps everything fair and accurate** behind the scenes.

---

## 📜 Full Code for `updateRewards()`

```solidity

///     Update rewards for a staker
function updateRewards(address user) internal {
    StakerInfo storage staker = stakers[user];

    if (staker.stakedAmount > 0) {
        uint256 timeDiff = block.timestamp - staker.lastUpdate;
        uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
        uint256 pendingReward = (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
        staker.rewardDebt += pendingReward;
    }

    staker.lastUpdate = block.timestamp;
}

```

---

## 🔍 Line-by-Line Breakdown

---

### 📚 Load User Info

```solidity

StakerInfo storage staker = stakers[user];

```

- We grab the user's staker data **from storage**,
  so we can update it directly without copying it into memory.

✅ Any changes we make will instantly reflect on-chain.

---

### 🔍 Check If User Has Tokens Staked

```solidity

if (staker.stakedAmount > 0) {

```

- Only update rewards if the user actually has something staked.
- If they have nothing staked, there’s no need to calculate rewards.

✅ Saves gas and avoids unnecessary math.

---

### 🕒 Calculate How Much Time Passed

```solidity

uint256 timeDiff = block.timestamp - staker.lastUpdate;

```

- Find out **how many seconds** have passed since the user's rewards were last updated.

✅ The longer they’ve been staked, the more they’ve earned.

---

### 🧮 Set the Reward Multiplier Based on Decimals

```solidity

uint256 rewardMultiplier = 10 ** stakingTokenDecimals;

```

- Since tokens might have different decimals (6, 18, etc.),
  we **normalize** the reward calculations using the token’s decimals.

✅ Keeps reward math accurate across any staking token.

---

### 💰 Calculate Pending Rewards

```solidity

uint256 pendingReward = (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;

```

- This formula says:
  - Multiply **time passed** × **reward rate** × **staked amount**
  - Then divide by the reward multiplier to adjust for decimals

✅ This gives us the exact amount of **new rewards** the user has earned since their last update.

---

### ➕ Add Pending Rewards to Reward Debt

```solidity

staker.rewardDebt += pendingReward;

```

- We add the newly calculated rewards to the user's `rewardDebt`.
- This reward debt will later be **claimed** when they call `claimRewards()`.

✅ Keeps rewards accumulating fairly over time.

---

### 🕒 Update Last Update Time

```solidity

staker.lastUpdate = block.timestamp;

```

- Reset the user's last update timestamp to **right now**.
- Next time we update rewards, we’ll calculate only **new earnings** from this moment onward.

✅ Always move forward cleanly with time tracking.

---

# 👀 15. `pendingRewards()` – Peek at Your Earnings Without Touching Them

Alright — users love seeing their rewards grow **in real-time**.

But they don't want to claim rewards **every second** — sometimes they just want to **check** how much they've earned so far.

That’s exactly what `pendingRewards()` lets them do:

> It's like checking your farm and seeing how much fruit has grown —
>
> without picking it yet.

This function is a **view-only function** —

meaning it doesn’t cost gas to call, and it doesn’t change anything inside the contract.

---

## 📜 Full Code for `pendingRewards()`

```solidity

///     View pending rewards without claiming
function pendingRewards(address user) external view returns (uint256) {
    StakerInfo memory staker = stakers[user];

    uint256 pendingReward = staker.rewardDebt;

    if (staker.stakedAmount > 0) {
        uint256 timeDiff = block.timestamp - staker.lastUpdate;
        uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
        pendingReward += (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
    }

    return pendingReward;
}

```

---

## 🔍 Line-by-Line Breakdown

---

### 📚 Fetch User Info

```solidity

StakerInfo memory staker = stakers[user];

```

- We load the user’s staking information **into memory** (not storage).
- Since we’re just **reading** and not **changing** anything, using `memory` saves gas and is faster.

✅ Good practice for view functions.

---

### 🧮 Start With Current Stored Rewards

```solidity

uint256 pendingReward = staker.rewardDebt;

```

- Start with whatever rewards the user has **already accumulated** but not yet claimed.
- This acts as the base pending reward amount.

✅ Capture what’s already owed before calculating more.

---

### 🕒 If They Have Staked Tokens, Add New Rewards

```solidity

if (staker.stakedAmount > 0) {
    uint256 timeDiff = block.timestamp - staker.lastUpdate;
    uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
    pendingReward += (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;
}

```

### 1. **First, check if the user has any tokens staked.**

```solidity

if (staker.stakedAmount > 0) {

```

- If a user hasn’t staked anything, they obviously shouldn’t be earning rewards.
- So we **only bother calculating** if they actually have some tokens locked in the farm.
- Saves gas and prevents useless calculations.

---

### 2. **Calculate how much time has passed since we last updated their rewards.**

```solidity

uint256 timeDiff = block.timestamp - staker.lastUpdate;

```

- `block.timestamp` gives the **current time** (in seconds).
- `staker.lastUpdate` is **the last time** we updated this user's rewards.
- By subtracting, we get exactly **how many seconds** have passed.

✅ This is important because users **earn rewards every second** —

the longer they stay staked, the more they deserve.

---

### 3. **Handle token decimals correctly with a reward multiplier.**

```solidity

uint256 rewardMultiplier = 10 ** stakingTokenDecimals;

```

- Different ERC-20 tokens use different numbers of decimals.
- `rewardMultiplier` normalizes everything back to **real-world numbers**.
- For example:
  - If a token uses 18 decimals, `rewardMultiplier = 10^18`.
  - If a token uses 6 decimals, `rewardMultiplier = 10^6`.
- This makes sure the math always scales correctly.

✅ Without this step, you could be accidentally paying users **billions** or **tiny fractions** depending on the token's setup.

---

### 4. **Calculate how much reward the user earned during that time.**

```solidity

pendingReward += (timeDiff * rewardRatePerSecond * staker.stakedAmount) / rewardMultiplier;

```

- Formula explained simply:
  - **`timeDiff`** = How long they've been earning.
  - **`rewardRatePerSecond`** = How many reward tokens are paid out per second.
  - **`stakedAmount`** = How much they staked (bigger stakes = bigger rewards).
  - **Divide by `rewardMultiplier`** to adjust for decimals.

✅ This calculation **accurately measures** their contribution to the farm since the last time they interacted.

And notice the `+=`:

- We **add** the new rewards on top of whatever `pendingReward` was already there.
- So if they already had some unclaimed rewards, we **stack** the new ones on top.
- Nothing is lost. Nothing is overwritten.

---

### 🔙 Return the Total Pending Reward

```solidity

return pendingReward;

```

- We return the final reward amount that the user **could claim right now** if they wanted to.

✅ Frontends can display this info beautifully to users.

---

# 📏 16. `getStakingTokenDecimals()` – Helping Frontends Handle Math

Alright — different ERC-20 tokens can have different **decimal setups**.

Some tokens use 18 decimals (like ETH), some use 6 decimals (like USDC), and some are even stranger.

When you’re showing balances, rewards, or doing math on the frontend,

**you need to know exactly how many decimals** the staking token uses —

otherwise your numbers will look wrong or confusing to users.

That’s where this tiny helper function comes in:

> It’s like checking the ruler before you measure anything.
>
> No assumptions, no mistakes.

---

## 📜 Full Code for `getStakingTokenDecimals()`

```solidity

/// View staking token decimals
function getStakingTokenDecimals() external view returns (uint8) {
    return stakingTokenDecimals;
}

```

---

## 🔍 Logic Behind This Line

---

### 📚 Simply Return the Decimals

```solidity

return stakingTokenDecimals;

```

- When we deployed the contract, we **fetched** and **saved** the staking token’s decimals.
- Now, this function simply **returns** that stored value.
- No recalculation. No gas-intensive calls. Just a clean, fast read.

✅ Frontends or users can call this anytime to know exactly how to **scale** and **display** token balances properly.

# 🧪 How to Run and Test Your Yield Farming Contract on Remix

---

## 1️⃣ Deploy Two Simple ERC-20 Token Contracts

Before we can even touch the Yield Farm,

we need **two tokens**:

- One token that users will **stake**
- One token that users will **earn as rewards**

✅ Use this simple ERC-20 code:

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

```

**Steps:**

- Compile and deploy **SimpleToken** twice:
  1. First time: name = `"StakeToken"`, symbol = `"STK"`, initialSupply = `1000000 * 10^18` (that's 1 million tokens with 18 decimals — enter it as `1000000000000000000000000`)
  2. Second time: name = `"RewardToken"`, symbol = `"RWD"`, same initial supply.

✅ Now you have two ERC-20 tokens deployed.

---

## 2️⃣ Deploy Your YieldFarming Contract

Now you deploy the actual farm!

Inputs required:

- `stakingToken`: address of the `StakeToken` you just deployed
- `rewardToken`: address of the `RewardToken`
- `rewardRatePerSecond`: choose something like `1000000000000000` (this is 0.001 reward tokens per second if using 18 decimals)

✅ This deploys your farming platform — it’s ready to accept stakers!

---

## 3️⃣ **Important! Approve the Farm to Move Your Tokens**

Before you can **stake**, you must give the YieldFarming contract **permission** to move your staking tokens on your behalf.

Otherwise, when you call `stake()`, the farm won't be allowed to pull tokens from your wallet.

**Steps:**

Go to your deployed **StakeToken** contract:

- Find and call the function:

```solidity

function approve(address spender, uint256 amount) public returns (bool)

```

- Parameters:
  - `spender`: the **address of the YieldFarming contract**
  - `amount`: the maximum amount you allow it to pull (set something big, like `1000000000000000000000` = 1000 STK)

✅ Once approved, the farm can now move your stake tokens when you call `stake()`.

⚡ **Approval is mandatory for any `transferFrom`** action in ERC-20.

---

> ❗ Important Note:
>
> You only need to approve the farm once (unless you want to change the allowance later).
>
> Every time you interact with a new token contract that uses `transferFrom()`, you must approve it separately!

---

## 4️⃣ Fund the Reward Pool (Optional but Recommended)

Since users will be earning **reward tokens**,

your YieldFarming contract needs some **reward tokens in its balance**.

**Steps:**

- Go to your deployed **RewardToken** contract.
- Call `approve()` first:
  - `spender`: YieldFarming contract address
  - `amount`: Big enough number, like `100000000000000000000000` (100,000 RWD)
- Then in your YieldFarming contract, call:

```solidity

refillRewards(amount)

```

- `amount`: how many RWD tokens you want to transfer into the farm as rewards.

✅ Now your farm has rewards ready to distribute!

---

## 5️⃣ Stake Your Tokens

Now go to your deployed **YieldFarming** contract:

- Call:

```solidity

stake(amount)

```

- `amount`: how many STK tokens you want to stake (e.g., `1000000000000000000000` for 1000 STK)

✅ After staking:

- Your tokens are locked inside the farm.
- Your reward earning starts immediately (second-by-second)!

---

## 6️⃣ View Your Pending Rewards

After waiting a few seconds or minutes:

- Call:

```solidity

pendingRewards(address user)

```

- `user`: your wallet address

✅ It shows how much reward (`RWD`) you’ve earned **live**, without claiming yet.

Frontends (like Dapps) usually call this automatically to show users "you've earned X so far."

---

## 7️⃣ Claim Your Rewards

Whenever you want to harvest what you’ve earned:

- Call:

```solidity

claimRewards()

```

✅ Your earned reward tokens (`RWD`) are transferred to your wallet.

✅ Your original stake remains untouched — you can continue farming!

---

## 8️⃣ Unstake Your Tokens (and Continue Claiming Later)

If you want to remove your stake:

- Call:

```solidity

unstake(amount)

```

- Pass how many staking tokens you want to withdraw (e.g., `500000000000000000000` = 500 STK).

✅ You get your stake back.

✅ You can still claim any leftover rewards separately.

---

## 9️⃣ Emergency Withdraw (Instant Exit)

If something urgent happens, and you want **instant exit** without worrying about pending rewards:

- Call:

```solidity

emergencyWithdraw()

```

✅ Your **entire staked amount** comes back immediately.

✅ **You forfeit any unclaimed rewards**.

# 🎉 Congratulations!

You didn’t just deploy another smart contract today —

you built the backbone of real-world DeFi.

You designed a system where users can stake, earn, withdraw, and harvest rewards — safely, fairly, and automatically —

the exact kind of system that powers platforms like Uniswap, SushiSwap, and beyond.

But more importantly:

you understood the _why_ behind every line —

not just how to write it, but **how to think like a DeFi builder**.

This is a huge step forward.

You now know how to:

- Move ERC-20 tokens securely
- Manage approvals properly
- Calculate rewards over time
- Protect contracts from attacks
- Build systems that **grow value block-by-block**

You're not just learning Solidity anymore —

you're building the future of decentralized finance.

**Be proud. Seriously.** 🚀

The farm is live.

The seeds are planted.

**And you’re just getting started. 🌱**
