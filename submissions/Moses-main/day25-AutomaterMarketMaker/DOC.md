# Automated Market Maker

Welcome back to **30 Days of Solidity** — where every day, we turn one complex concept into code you can actually understand.

Today, we’re going to demystify one of the most legendary mechanisms in all of DeFi:

The **Automated Market Maker** — or AMM.

---

It’s one of the **most powerful inventions in DeFi** — the kind of thing that helped turn smart contracts into full-blown financial applications.

We’re talking about:

### The **Automated Market Maker** — a.k.a. the AMM.

But don’t worry if that sounds fancy —

because by the end of this, you’ll not only know what an AMM is,

you’ll be able to build one.

Let’s start with the story of **why** AMMs even exist.

---

## 🏛️ Back Then: How People Used to Trade Crypto

Let’s go back to how trading originally worked — even in the early days of crypto:

It was just like a stock market.

- You had **buyers**, who said:
  _“I want to buy 1 DAI, and I’ll pay 0.95 ETH for it.”_
- You had **sellers**, who said:
  _“I have 1 DAI to sell, but I want 1 ETH for it.”_
- And sitting in the middle was a system called an **order book**.
  Think of it like a giant list, matching buyers and sellers.

When a buyer and a seller both agreed on a price? Boom — the trade happened.

This system works great on centralized exchanges like Binance or Coinbase.

But there’s a problem…

---

## 🤕 Why That Doesn't Work On-Chain

On a blockchain, everything costs **gas**.

Even something as simple as saying “I want to buy DAI” means:

- Sending a transaction
- Paying a fee
- Waiting for it to confirm

Imagine having to do that for **every tiny change** to your buy or sell price. That’s a nightmare.

And what if no one wants to trade with you at that moment?

You’re stuck. Your order just sits there, wasting gas and time.

So here’s the core issue:

- Order books are **centralized**
- They need people to be active all the time
- They’re slow and expensive to use on-chain

DeFi needed something **better**.

---

## 💡 The Breakthrough: What If We Didn’t Need Buyers and Sellers?

Here’s the brilliant idea that changed everything:

> What if people didn’t need to wait for a trading partner?

> What if a smart contract could just act like a vending machine for tokens?

So instead of relying on other people to trade with…

You’d have a pool of two tokens — like DAI and ETH —

locked in a contract that anyone can use.

Want to **buy ETH with DAI**?

The contract does the math, gives you ETH, and keeps your DAI.

Want to **sell ETH for DAI**?

Same thing — the contract gives you DAI and stores your ETH.

No need for buyers. No need for sellers. Just math.

---

## 📐 Okay… But How Does It Actually Work?

The AMM uses a simple formula:

> x × y = k

Let’s break that down.

- `x` = amount of Token A in the pool
- `y` = amount of Token B in the pool
- `k` = some constant number (it never changes)

So the **product of the two token reserves must always stay the same**.

Here’s the magic:

If someone wants to add more of Token A (like ETH),

the only way to keep `k` constant is for the contract to give them _less_ of Token B (like DAI).

That’s how prices adjust — **automatically**.

As people trade more, the ratio shifts — and the price updates on its own.

That’s why it’s called an **Automated Market Maker**.

The contract _makes the market_ using math, not human orders.

---

## 🔁 So What Can You Do With an AMM?

There are three big things you can do:

1. **Swap** tokens
   - Instantly trade Token A for Token B (or the other way around)
   - No need to wait for a match
   - Just send the token, get the other back
2. **Add liquidity**
   - Deposit equal value of Token A and B
   - You get **LP tokens** (like a receipt)
   - You earn a cut of trading fees while your tokens are in the pool
3. **Remove liquidity**
   - Return your LP tokens
   - Get your share of both tokens back

---

Now that you get the idea...

In the next section, we’ll look at an actual Solidity contract — and walk through how to **code your own AMM**, from scratch.

We’ll show:

- How the liquidity pool works
- How the price math is calculated
- And how to make sure everything stays fair and balanced

Ready to build the engine behind DeFi?

Let’s get to the code.

---

## 🛠️ What You’re Building Today

Alright, so today’s project is not just a toy contract.

You're building the **core engine** that powers billions of dollars in decentralized trading.

But here’s the twist:

- **No libraries**
- **No shortcuts**
- **No behind-the-scenes magic**

You're going to write the heart of an Automated Market Maker **by hand** — and that’s the best way to _truly_ understand how it works.

Let’s break down exactly what your smart contract will do, and why each piece matters:

---

### 🔁 Create a Liquidity Pool Between Two ERC-20 Tokens

You’ll start by locking up two ERC-20 tokens — let’s call them **Token A** and **Token B** — in a smart contract.

These tokens form the **liquidity pool**.

This pool is what people will interact with to either **swap tokens** or **provide liquidity**. It’s like the vault that holds all the trading assets.

---

### ➕ Let Users Add and Remove Liquidity

Anyone can deposit equal values of Token A and Token B into the pool.

Why equal value?

Because it keeps the **price ratio** in balance.

When someone adds liquidity:

- You store their tokens in the contract
- You issue them **LP tokens** (short for liquidity provider tokens) — these are like a digital receipt

Later, when they remove liquidity, they give back those LP tokens — and you return their share of both tokens.

This way, everyone has **proof of ownership** of their slice of the pool.

---

### 🧮 Track and Update Internal Reserves

Your contract will keep track of two numbers at all times:

- `reserveA`: how much Token A is in the pool
- `reserveB`: how much Token B is in the pool

Every time someone adds or removes tokens, or makes a swap, these reserves update.

These values are **crucial** because they’re used to:

- Calculate fair prices
- Enforce the constant product formula (more on that in a sec)
- Prevent abuse or manipulation

---

### 🔁 Allow Anyone to Swap Token A for Token B (and Vice Versa)

This is the bread and butter of an AMM.

Let’s say Alice wants to trade some of her Token A for Token B.

Your contract:

- Accepts her Token A
- Calculates how much Token B to give her (based on the current pool ratio)
- Updates the reserves
- Transfers the tokens

All of this happens **without needing a counterparty** — no seller required on the other side.

The same logic works the other way too — swapping Token B for Token A.

---

### 📐 Use the Constant Product Formula

Now here’s where the magic happens.

Your contract will use this formula to determine the swap rate:

> x \* y = k

Where:

- `x` = reserve of Token A
- `y` = reserve of Token B
- `k` = constant value that must never change

When someone adds Token A to the pool, the only way to keep `k` constant is to **remove some Token B** — and vice versa.

That’s how price discovery happens. It’s automatic. It’s fair. And it’s math-based.

To prevent abuse, you'll also apply a small fee (like 0.3%) on each trade — just like Uniswap — and that fee goes to the liquidity providers.

---

### 🎟️ Issue Custom LP Tokens

Remember when people added liquidity and got those "receipts"?

Those LP tokens represent their **ownership stake** in the pool.

If the pool grows because of trading fees, LPs benefit — because they can withdraw **more** than they put in.

You’ll extend the ERC-20 contract to issue and manage these LP tokens yourself.

---

This contract might look simple on the surface — just a few functions, a few math formulas…

But under the hood?

You’re recreating the fundamental building blocks of a **decentralized exchange** — the kind that runs on Ethereum, without any humans, brokers, or middlemen.

And the best part?

You're writing it line by line — fully transparent, fully decentralized, and fully under your control.

Let’s build.

---

# Contract Breakdown

Alright, now that you understand **what** an Automated Market Maker is and **why** it matters, it’s time to look under the hood.

What you’re about to see is the **full code** of a working AMM — and don’t worry if it looks intimidating at first. We’re going to walk through it **step by step**, and explain everything in plain language.

From the imports at the top…

To how liquidity is added and removed…

To the exact math behind token swaps…

By the end of this breakdown, you'll know:

- How ERC-20 tokens are integrated into smart contracts
- How reserve balances are tracked and updated
- What the `x * y = k` formula actually looks like in code
- And how custom LP tokens get minted and burned

So take a breath, scroll slow — and let’s start decoding this line by line.

This is where it all starts to click.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Automated Market Maker with Liquidity Token
contract AutomatedMarketMaker is ERC20 {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    address public owner;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokensSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    /// @notice Add liquidity to the pool
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 liquidity;
        if (totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min(
                amountA * totalSupply() / reserveA,
                amountB * totalSupply() / reserveB
            );
        }

        _mint(msg.sender, liquidity);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity from the pool
    function removeLiquidity(uint256 liquidityToRemove) external returns (uint256 amountAOut, uint256 amountBOut) {
        require(liquidityToRemove > 0, "Liquidity to remove must be > 0");
        require(balanceOf(msg.sender) >= liquidityToRemove, "Insufficient liquidity tokens");

        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity > 0, "No liquidity in the pool");

        amountAOut = liquidityToRemove * reserveA / totalLiquidity;
        amountBOut = liquidityToRemove * reserveB / totalLiquidity;

        require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");

        reserveA -= amountAOut;
        reserveB -= amountBOut;

        _burn(msg.sender, liquidityToRemove);

        tokenA.transfer(msg.sender, amountAOut);
        tokenB.transfer(msg.sender, amountBOut);

        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);
        return (amountAOut, amountBOut);
    }

    /// @notice Swap token A for token B
    function swapAforB(uint256 amountAIn, uint256 minBOut) external {
        require(amountAIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountAInWithFee = amountAIn * 997 / 1000;
        uint256 amountBOut = reserveB * amountAInWithFee / (reserveA + amountAInWithFee);

        require(amountBOut >= minBOut, "Slippage too high");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        reserveA += amountAInWithFee;
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    /// @notice Swap token B for token A
    function swapBforA(uint256 amountBIn, uint256 minAOut) external {
        require(amountBIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountBInWithFee = amountBIn * 997 / 1000;
        uint256 amountAOut = reserveA * amountBInWithFee / (reserveB + amountBInWithFee);

        require(amountAOut >= minAOut, "Slippage too high");

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBInWithFee;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
    }

    /// @notice View the current reserves
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    /// @dev Utility: Return the smaller of two values
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Utility: Babylonian square root
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

```

Alright, let’s start breaking this contract down in the most beginner-friendly way possible.

---

---

###

# 🧱 2. Importing the ERC20 Standard

```solidity

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

```

Let’s start with this line — it's simple, but super powerful.

Here, we’re importing the **ERC20 contract from OpenZeppelin**.

> 🧰 What’s OpenZeppelin?
>
> It’s a library of battle-tested, secure smart contracts that are widely used across the Ethereum ecosystem. Think of it like importing Lego pieces you can trust — instead of trying to build every brick from scratch.

> 📦 What’s ERC20?
>
> ERC-20 is a standard for creating tokens on Ethereum. Most tokens you’ve heard of — like DAI, USDC, or UNI — follow this standard. It defines how tokens behave, including:

- How to send and receive them (`transfer`)
- How to give someone else permission to use them (`approve` + `transferFrom`)
- How to check balances (`balanceOf`)
- And even how to create or destroy tokens (`mint` and `burn`, if allowed)

By importing `ERC20.sol`, we instantly get access to **all that functionality**, without having to rewrite any of it ourselves.

> ✨ Why do we need this here?
> Because our AMM contract also issues its own tokens — the LP tokens that users receive when they provide liquidity. These LP tokens are just standard ERC-20 tokens — and by inheriting from the ERC20 contract, we can mint them just like any other token.

This one import sets up the entire backbone for LP token functionality.

---

### 🧾 3. Contract Declaration

```solidity

contract AutomatedMarketMaker is ERC20 {

```

This line kicks off our main smart contract.

Let’s break it down:

- `contract AutomatedMarketMaker`:
  This defines a new contract called `AutomatedMarketMaker`. This will be the **brain of our AMM**, holding tokens, calculating swaps, and tracking liquidity.
- `is ERC20`:
  This means our contract is **inheriting from the ERC20 contract** we just imported.

Think of inheritance like saying:

> “Hey Solidity, my contract should behave just like an ERC20 token — and on top of that, I’ll add some extra AMM-specific logic.”

Because of this inheritance, we don’t need to manually code the ERC-20 behavior — it’s already baked in. We’ll simply call functions like `_mint()` and `_burn()` when we need to issue or destroy LP tokens.

> 🎟️ Why does the AMM need its own token?
>
> Every time someone provides liquidity, we give them a token that represents their **share of the pool**. That’s the LP token. It behaves just like any other ERC-20 token — it can be transferred, tracked, and later redeemed for a cut of the pool.

So this line is more than just a declaration — it’s the start of making our AMM behave like both a token issuer and a decentralized exchange, all in one smart contract.

---

# 🧮 4. State Variables

```solidity

IERC20 public tokenA;
IERC20 public tokenB;

uint256 public reserveA;
uint256 public reserveB;

address public owner;

```

These are the **core variables** that store the important state of our AMM.

Think of them as the contract’s internal memory — they keep track of what tokens it’s dealing with, how much of each it holds, and who deployed the contract.

Let’s break each one down:

---

### 🪙 `tokenA` and `tokenB`

```solidity
IERC20 public tokenA;
IERC20 public tokenB;
```

- These two variables hold the **addresses** of the ERC-20 tokens this AMM will manage.
- They’re typed as `IERC20`, which is just an interface — a way of saying:
  > “Hey, this thing behaves like an ERC-20 token, so I know it has transfer, transferFrom, approve, and other ERC-20 functions.”

So if this AMM is used to trade **DAI and USDC**, then `tokenA` might be DAI, and `tokenB` would be USDC.

> ✅ Why public?
>
> Because we want these to be **viewable** from the outside — for frontends, explorers, or other contracts.

---

### 🧾 `reserveA` and `reserveB`

```solidity

uint256 public reserveA;
uint256 public reserveB;

```

These two numbers track how much of each token is currently locked inside the AMM contract.

Why do we need this?

Because the **entire AMM logic — swaps, prices, LP shares — depends on knowing how much of each token is in the pool.**

When someone swaps tokens:

- We update these reserves
- We use them in the formula `x * y = k` to calculate how much they get in return

> 🎯 Important: These aren't automatically updated by the token balances — we update them manually whenever we make a change (like a swap or liquidity move).

---

### 🧑‍💼 `owner`

```solidity

address public owner;

```

This stores the address that **deployed** the contract.

Right now, we’re not using it for any admin-only features… but it’s a good pattern to include if we ever want to:

- Add governance
- Let the owner pause swaps in an emergency
- Or introduce a fee switch later

> 🔐 It's a simple way to track who controls the contract — or just to tag who deployed it in the first place.

---

Together, these variables define the **core identity and state of the AMM**:

- What tokens it supports
- How much liquidity it has
- Who owns or manages it

---

# 🔔 5. Events

```solidity

event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
event TokensSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

```

These are **events**, and while they don’t affect how the contract works under the hood, they play a **huge role** in how apps and users interact with it.

Think of events as **on-chain notifications** or **console logs for the blockchain**.

Every time one of these key actions happens — adding liquidity, removing liquidity, or swapping tokens — we fire off an event.

Let’s go through each one:

---

### 💧 `LiquidityAdded`

```solidity

event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);

```

- This is triggered whenever someone **adds tokens** to the pool.
- It records:
  - Who added the liquidity (`provider`)
  - How much of tokenA and tokenB they added
  - And how many **LP tokens** they got in return

> 🧠 Why is this useful?
>
> Because dapps can **listen for this event** and show it in the UI. For example, a website might display:
>
> “You added 100 DAI and 100 USDC to the pool. You received 99 LP tokens.”

---

### 💸 `LiquidityRemoved`

```solidity

event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);

```

- This one logs when someone **removes liquidity** from the pool.
- It shows:
  - Who withdrew
  - How much of each token they got back
  - And how many LP tokens they burned to do it

> 🔍 Frontends use this to update your pool position or history.

---

### 🔄 `TokensSwapped`

```solidity

event TokensSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);
```

- This is fired whenever someone **swaps** one token for the other.
- It tells us:
  - Who did the swap (`trader`)
  - What token they gave in (`tokenIn`)
  - How much they gave
  - What token they got out (`tokenOut`)
  - And how much they received

> 🖥️ With this, dapps can instantly show a swap confirmation like:
>
> “You swapped 10 DAI for 9.87 USDC.”

---

# 🚀 6. Constructor – Setting Things Up

```solidity

constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
  tokenA = IERC20(_tokenA);
  tokenB = IERC20(_tokenB);
  owner = msg.sender;
}

```

Alright — this function might look small, but it’s **crucial**.

This is the **constructor**, and it runs **once** — and only once — when the contract is deployed to the blockchain.

Let’s walk through it step by step.

---

### 🔧 What does the constructor do?

It’s like setting up the initial configuration of a machine before anyone uses it. You define:

- What tokens this AMM will support
- What to call the LP token
- Who deployed the contract (and might control upgrades or special actions later)

---

### 📬 Parameters

```solidity

constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol)

```

This constructor takes **four inputs**:

1. `_tokenA`: the address of the first ERC-20 token (e.g., DAI)
2. `_tokenB`: the address of the second ERC-20 token (e.g., USDC)
3. `_name`: the name for the LP token (e.g., “DAI-USDC LP Token”)
4. `_symbol`: the symbol for the LP token (e.g., “DAIUSDC-LP”)

> 📝 The string memory type is just a Solidity way of saying:
>
> “We’re passing this string around temporarily — not storing it in a fixed-length location.”

---

### 🎟️ `ERC20(_name, _symbol)`

```solidity

ERC20(_name, _symbol)

```

This part is sneaky but important.

Because our AMM contract inherits from `ERC20`, we’re calling its constructor here to set up the **name and symbol** of the LP token this contract will mint.

So if someone adds liquidity, they might get a token called:

> “DAI-USDC LP Token (DAIUSDC-LP)”

Just like how USDC has its name and symbol — your LP token will too.

---

### 🪙 Token Setup

```solidity

tokenA = IERC20(_tokenA);
tokenB = IERC20(_tokenB);

```

This part assigns the actual token contracts to our state variables.

We take the two addresses passed in (`_tokenA` and `_tokenB`) and treat them as ERC-20 tokens using the `IERC20` interface. This gives us access to:

- `transfer()`
- `transferFrom()`
- `balanceOf()`
- And other token-related functions

It’s how this AMM knows **which tokens it’s working with**.

---

### 👑 Ownership

```solidity

owner = msg.sender;

```

This sets the `owner` variable to whoever deployed the contract.

- `msg.sender` is a global variable in Solidity — it always refers to the address that called the function.
- In a constructor, that’s the deployer.

We’re not using `owner` for anything admin-like _yet_, but keeping track of the deployer is a good pattern — in case you want to introduce governance or fee routing later on.

---

# 🧰 Helper Functions – Small Tools, Big Purpose

```solidity

function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
}

function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
}

```

---

## 🔽 `min()`: Return the Smaller Number

```solidity

function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
}

```

This function is used to pick the **smaller of two numbers**.

Why do we need this?

👉 In `addLiquidity()`, when someone is adding tokens to an existing pool, we want to mint LP tokens based on **whichever token amount would contribute less** to the pool — to keep the ratio stable and prevent overminting.

> If the user sends 100 A and 150 B, we’ll use 100 A and only 100 B worth of B tokens to mint LP tokens — and return the extra 50 B to the pool unused.

This `min()` function keeps things **balanced** and **fair**.

---

## 🧮 `sqrt()`: Babylonian Square Root

```solidity

function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
}

```

This is a classic **Babylonian algorithm** for calculating the square root of a number in Solidity — since Solidity doesn't have a built-in `sqrt()` function like some other languages.

> It’s used exactly once — but for a very important reason:

### 🎯 Where do we use it?

In `addLiquidity()`, **the very first liquidity provider** gets LP tokens equal to:

```solidity

sqrt(amountA * amountB)

```

This ensures:

- The LP token supply starts at a balanced value
- It reflects the geometric mean of the two token amounts added

So even if you added 100 A and 400 B, your LP tokens would be based on √(100×400) = √40000 = 200, rather than just the raw sum.

It’s a fair and math-driven way to start the pool.

### 🧠 Why Put These in the Contract?

- They’re small, **pure** functions (no storage read/write).
- They're used internally to keep your logic clean.
- And they help prevent bugs, especially when you're dealing with token math where fairness matters.

We will be Using these functions in the following functions

# 💧 7. Add Liquidity – Feeding the Pool

```solidity

function addLiquidity(uint256 amountA, uint256 amountB) external {
    require(amountA > 0 && amountB > 0, "Amounts must be > 0");

    tokenA.transferFrom(msg.sender, address(this), amountA);
    tokenB.transferFrom(msg.sender, address(this), amountB);

    uint256 liquidity;
    if (totalSupply() == 0) {
        liquidity = sqrt(amountA * amountB);
    } else {
        liquidity = min(
            amountA * totalSupply() / reserveA,
            amountB * totalSupply() / reserveB
        );
    }

    _mint(msg.sender, liquidity);

    reserveA += amountA;
    reserveB += amountB;

    emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
}

```

---

### 🧠 What’s the Overall Idea?

This function lets a user **add liquidity** to the pool by depositing **equal value amounts** of Token A and Token B.

In return, the user receives **LP tokens** (liquidity provider tokens), which represent their **share of the pool**.

> These LP tokens are like a “receipt” — proof that you contributed to the pool, and a claim to your share of the tokens inside it.

The first person to add liquidity sets the initial price.

Everyone after that has to deposit tokens in the **same ratio** as the current pool — to keep the price fair.

---

### 🧩 Let’s Break it Down Line by Line:

---

### ✅ Input Check

```solidity

require(amountA > 0 && amountB > 0, "Amounts must be > 0");

```

We start with a basic sanity check.

- We don’t want people to add zero tokens.
- This protects the contract from weird behavior or wasted gas.

---

### 💸 Transfer Tokens to the Pool

```solidity

tokenA.transferFrom(msg.sender, address(this), amountA);
tokenB.transferFrom(msg.sender, address(this), amountB);

```

Now the user actually sends their tokens to the contract.

- We use `transferFrom()` because the user needs to **approve** the contract to take their tokens first.
- This is standard ERC-20 behavior — the user must call `approve()` beforehand.

> So, they’re giving the contract amountA of Token A and amountB of Token B.

---

### 📐 Calculate LP Tokens to Mint

```solidity

uint256 liquidity;
if (totalSupply() == 0) {
    liquidity = sqrt(amountA * amountB);
} else {
    liquidity = min(
        amountA * totalSupply() / reserveA,
        amountB * totalSupply() / reserveB
    );
}

```

This part decides **how many LP tokens** to give the user.

- If they’re the **first person ever** to add liquidity, there’s no LP supply yet.
  - So we give them: `sqrt(amountA * amountB)`
  - This is a standard formula used by Uniswap to give a fair starting point.
- If the pool already has liquidity:
  - We calculate how much they should get based on **proportional contribution**.
  - We make sure the user adds liquidity in the **correct ratio**.
  - We use `min()` to avoid over-minting LP tokens if the user’s amounts are slightly off.

> This ensures everyone’s share of the pool is fair.

---

### 🖨️ Mint LP Tokens

```solidity

_mint(msg.sender, liquidity);

```

Now we actually give the user their LP tokens.

Since our contract extends `ERC20`, we can call `_mint()` to issue new tokens directly to the user.

---

### 📊 Update Reserves

```solidity

reserveA += amountA;
reserveB += amountB;

```

We update the internal state of the contract to reflect the new tokens that were added.

This is **super important** because the swap math depends on these values staying accurate.

---

### 🔔 Emit an Event

```solidity

emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);

```

This logs the action so that frontends and dapps can show users what just happened.

It includes:

- Who added liquidity
- How much they added
- How many LP tokens they received

---

# 🧯 8. Remove Liquidity – Withdrawing Your Share

```solidity

function removeLiquidity(uint256 liquidityToRemove) external returns (uint256 amountAOut, uint256 amountBOut) {
    require(liquidityToRemove > 0, "Liquidity to remove must be > 0");
    require(balanceOf(msg.sender) >= liquidityToRemove, "Insufficient liquidity tokens");

    uint256 totalLiquidity = totalSupply();
    require(totalLiquidity > 0, "No liquidity in the pool");

    amountAOut = liquidityToRemove * reserveA / totalLiquidity;
    amountBOut = liquidityToRemove * reserveB / totalLiquidity;

    require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");

    reserveA -= amountAOut;
    reserveB -= amountBOut;

    _burn(msg.sender, liquidityToRemove);

    tokenA.transfer(msg.sender, amountAOut);
    tokenB.transfer(msg.sender, amountBOut);

    emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);
    return (amountAOut, amountBOut);
}

```

---

### 🧠 What’s the Overall Idea?

This function lets a user **withdraw** their share of the tokens they previously added.

To do that, they give back (burn) their **LP tokens** — and in return, the contract gives them:

- A proportionate amount of Token A
- A proportionate amount of Token B

Everything is based on their share of the total liquidity pool.

If they owned 10% of the LP tokens, they’ll get 10% of each token in the pool.

Let’s now walk through what’s happening line by line:

---

### 🧩 Line-by-Line Breakdown:

---

### ✅ Input Checks

```solidity

require(liquidityToRemove > 0, "Liquidity to remove must be > 0");
require(balanceOf(msg.sender) >= liquidityToRemove, "Insufficient liquidity tokens");

```

- First, we make sure the user is trying to remove a positive number of LP tokens.
- Then, we confirm they actually **own** enough LP tokens to do so.
- `balanceOf(msg.sender)` checks how many LP tokens the user has.

This protects the contract from invalid or malicious inputs.

---

### 📊 Get the Total Supply of LP Tokens

```solidity

uint256 totalLiquidity = totalSupply();
require(totalLiquidity > 0, "No liquidity in the pool");

```

- We grab the **total supply** of LP tokens. This represents 100% ownership of the pool.
- If for some reason it’s zero, we prevent the transaction — that would mean there's no liquidity to redeem from.

---

### 🧮 Calculate Token Amounts to Return

```solidity

amountAOut = liquidityToRemove * reserveA / totalLiquidity;
amountBOut = liquidityToRemove * reserveB / totalLiquidity;

```

Here’s where the magic happens.

We use a simple proportion to calculate how much of each token the user should get back:

> their LP share × total token reserve = their withdrawal

If they own 25% of the LP tokens, they get back 25% of both tokenA and tokenB in the pool.

---

### ⛔ Final Sanity Check

```solidity

require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");

```

Just in case the math results in dust values (due to rounding), we reject if either output would be zero — to prevent broken or wasteful withdrawals.

---

### 🧾 Update Internal Reserves

```solidity

reserveA -= amountAOut;
reserveB -= amountBOut;

```

We subtract the withdrawn amounts from the internal record of reserves.

This keeps our swap math accurate — because every trade relies on these reserves being correct.

---

### 🔥 Burn LP Tokens

```solidity

_burn(msg.sender, liquidityToRemove);

```

Since the user is returning their LP tokens in exchange for the real tokens, we **burn** them — effectively deleting them from existence.

No double dipping.

---

### 💸 Transfer Tokens Back to the User

```solidity

tokenA.transfer(msg.sender, amountAOut);
tokenB.transfer(msg.sender, amountBOut);

```

Now we actually send the user back their share of tokens.

- They get `amountAOut` of Token A
- And `amountBOut` of Token B

All automatically handled by the contract.

---

### 🔔 Emit an Event

```solidity

emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);

```

This logs the action to the blockchain, so dapps, explorers, and indexers can pick it up.

It shows:

- Who withdrew
- How much they withdrew
- How many LP tokens were burned

---

### 📤 Return the Outputs

```solidity

return (amountAOut, amountBOut);

```

We return the amounts as a friendly reminder to whoever called the function — could be a contract or frontend that wants to show the result.

---

# 🔄 9. Swap A for B

```solidity
function swapAforB(uint256 amountAIn, uint256 minBOut) external {
    require(amountAIn > 0, "Amount must be > 0");
    require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

    uint256 amountAInWithFee = amountAIn * 997 / 1000;
    uint256 amountBOut = reserveB * amountAInWithFee / (reserveA + amountAInWithFee);

    require(amountBOut >= minBOut, "Slippage too high");

    tokenA.transferFrom(msg.sender, address(this), amountAIn);
    tokenB.transfer(msg.sender, amountBOut);

    reserveA += amountAInWithFee;
    reserveB -= amountBOut;

    emit TokensSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
}

```

Let’s say you’re using a DEX and want to swap some **Token A** for **Token B** — like trading ETH for DAI.

In a centralized exchange, a matching engine would pair you with someone else selling DAI.

But here? There’s no seller. You’re trading directly with a **smart contract**, using math.

This function lets users:

- Send some `Token A` to the contract
- Automatically receive the right amount of `Token B` back
- And the contract updates its internal token reserves to reflect the swap

But how does it figure out the right price?

---

### ⚙️ The Core Idea: Constant Product Formula

> x \* y = k

This is the formula behind every Uniswap v2-style AMM.

- `x` is how much Token A the contract has
- `y` is how much Token B the contract has
- `k` is a constant — the product of those two amounts

When someone adds Token A to the pool, the pool must give back **just enough Token B** to keep `x * y` constant (or very close to it, accounting for slippage and fees).

This means: the **more you try to swap**, the **worse your rate gets** — because you're pushing the price curve.

This design keeps the pool balanced, prevents manipulation, and automatically adjusts the price based on supply and demand.

---

### 🧩 Line-by-Line Breakdown

---

### ✅ Step 1: Sanity Check

```solidity

require(amountAIn > 0, "Amount must be > 0");
require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

```

- Make sure the user is actually trying to swap something (not zero).
- And make sure there’s liquidity in the pool — both tokens must be present.

If any of these are false, we stop the transaction early and **save gas**.

---

### 🧮 Step 2: Apply the 0.3% Fee

```solidity

uint256 amountAInWithFee = amountAIn * 997 / 1000;

```

Here’s where we subtract a **0.3% fee**.

- If you sent in `100 Token A`, only `99.7` gets used for the swap math.
- The remaining `0.3` stays in the pool — as a reward for liquidity providers.

This small fee prevents abuse (like spamming swaps) and makes the pool grow over time, which benefits LPs.

---

### 🔢 Step 3: Calculate How Much Token B You Get

```solidity

uint256 amountBOut = reserveB * amountAInWithFee / (reserveA + amountAInWithFee);

```

Let’s break this math down gently.

- We’re calculating how much **Token B** the user should get for the amount of **Token A** they’re putting in.
- `reserveA` is how much Token A the pool had _before_ the swap.
- `amountAInWithFee` is the new Token A being added _after_ applying the fee.
- The formula ensures that `x * y = k` stays roughly constant **after the trade**.

The more you add to the pool, the **less you get per unit**, because it pushes the ratio — this is called **price slippage**.

So it’s fair. It’s automatic. And it doesn’t need any humans to set prices.

---

### 🛡️ Step 4: Slippage Protection

```solidity

require(amountBOut >= minBOut, "Slippage too high");

```

Before we go any further, we check if the **actual output** is at least what the user expected.

- `minBOut` is set by the user — it’s their way of saying:
  > “I’ll only do this swap if I get at least X Token B.”

If the math gives them less than that, we revert the trade to protect them from **unexpected price movement**.

---

### 🔄 Step 5: Transfer Tokens

```solidity

tokenA.transferFrom(msg.sender, address(this), amountAIn);
tokenB.transfer(msg.sender, amountBOut);

```

- The contract **pulls** Token A from the user’s wallet using `transferFrom`
  (the user needs to `approve()` the contract beforehand).
- Then it **sends** Token B back to the user — completing the trade.

No order book. No counterparty. Just math and tokens.

---

### 📊 Step 6: Update Reserves

```solidity

reserveA += amountAInWithFee;
reserveB -= amountBOut;

```

We now update the contract’s record of how much of each token it holds.

> Why do we only add amountAInWithFee to reserveA?
>
> Because the fee portion doesn’t count toward swap logic — it's not available for the next trader.

---

### 🔔 Step 7: Emit an Event

```solidity

emit TokensSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);

```

We log everything that just happened — the swapper, tokens involved, amounts traded — so that dapps and UIs can pick it up and show it to the user.

---

# 🔁 10. Swap B for A – The Reverse Trade

```solidity

function swapBforA(uint256 amountBIn, uint256 minAOut) external {
    require(amountBIn > 0, "Amount must be > 0");
    require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

    uint256 amountBInWithFee = amountBIn * 997 / 1000;
    uint256 amountAOut = reserveA * amountBInWithFee / (reserveB + amountBInWithFee);

    require(amountAOut >= minAOut, "Slippage too high");

    tokenB.transferFrom(msg.sender, address(this), amountBIn);
    tokenA.transfer(msg.sender, amountAOut);

    reserveB += amountBInWithFee;
    reserveA -= amountAOut;

    emit TokensSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
}

```

---

### 🧠 What’s the Purpose?

This function is the **mirror** of `swapAforB()`.

It allows users to swap **Token B** into the pool and receive **Token A** in return — following the **same pricing logic**, the same **constant product formula**, and the same **0.3% fee**.

Everything is just flipped.

If you think of `Token A` as ETH and `Token B` as DAI, this would be the path for someone trying to **buy ETH using DAI**.

---

### 🧩 Line-by-Line Breakdown

---

### ✅ Step 1: Input Validation

```solidity

require(amountBIn > 0, "Amount must be > 0");
require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

```

Just like before:

- Make sure the input is non-zero.
- And that the pool has enough of both tokens to make the swap meaningful.

---

### 💸 Step 2: Apply the 0.3% Fee

```solidity

uint256 amountBInWithFee = amountBIn * 997 / 1000;

```

Again, we subtract a **0.3% fee** from the input before calculating the output.

This keeps the swap fair and **generates rewards for liquidity providers** over time.

---

### 📐 Step 3: Constant Product Math (B ➜ A)

```solidity

uint256 amountAOut = reserveA * amountBInWithFee / (reserveB + amountBInWithFee);

```

We use the same constant product formula:

> x \* y = k must remain (mostly) unchanged.

But now:

- `reserveB` is the current amount of Token B
- `amountBInWithFee` is what we’re adding
- And `reserveA` is used to calculate how much of Token A to give out

This math **automatically adjusts the exchange rate** based on the pool balance. The bigger your trade, the more the price shifts — this is called **price impact** or **slippage**.

---

### 🛡️ Step 4: Slippage Check

```solidity

require(amountAOut >= minAOut, "Slippage too high");

```

This line **protects the user**.

They specify a `minAOut` — the minimum amount of Token A they expect to receive.

If the pool's state changes too much and they’d get less than expected, the trade is canceled.

No surprises. No overpaying.

---

### 🔁 Step 5: Perform the Swap

```solidity

tokenB.transferFrom(msg.sender, address(this), amountBIn);
tokenA.transfer(msg.sender, amountAOut);

```

- We **pull in** Token B from the user.
- Then we **send out** the calculated amount of Token A to them.

The swap is complete — and fully permissionless.

---

### 📊 Step 6: Update Reserves

```solidity

reserveB += amountBInWithFee;
reserveA -= amountAOut;

```

We update our internal tracking of how many tokens are in the pool.

Notice:

- Only the **fee-adjusted amount** goes into the reserve.
- And the exact amount given to the user is removed from the other side.

This is important — our future swaps rely on these reserves being **100% accurate**.

---

### 🔔 Step 7: Emit Event

```solidity

emit TokensSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);

```

This event logs the full swap:

- Who traded
- What tokens were involved
- How much went in and out

UIs use this to give users instant feedback like:

> “You swapped 50 DAI for 0.027 ETH.”

---

### 🧠 Why This Matters

Together, `swapAforB()` and `swapBforA()` make the AMM a **fully functional decentralized exchange**.

- No matching engine
- No market makers
- No gatekeepers

Just pure, open math.

---

# 🧐 11. View Reserves – Exposing the Pool's State

```solidity

function getReserves() external view returns (uint256, uint256) {
    return (reserveA, reserveB);
}
```

---

### 🧠 What’s the Point of This Function?

This function is here to **expose the current state of the pool** — specifically, how much of **Token A** and **Token B** the contract is currently holding (i.e., the liquidity reserves).

It doesn't change anything.

It doesn’t cost gas (if called externally).

It just returns **two numbers**: the current reserves of each token.

And those numbers are **hugely important** for:

- Frontend apps (like a DEX UI)
- Wallet integrations
- Analytics dashboards
- Anyone trying to display price or liquidity info

---

### 🔍 Line-by-Line Breakdown

### Declaration:

```solidity

function getReserves() external view returns (uint256, uint256)

```

- `external`: This function is **meant to be called from outside the contract**, like a frontend.
- `view`: This tells Solidity **we’re not modifying any state**, just reading.
- `returns (uint256, uint256)`: We're returning two values — one for Token A, one for Token B.

---

### Return Statement:

```solidity

return (reserveA, reserveB);

```

- `reserveA` is how much of Token A is in the pool.
- `reserveB` is how much of Token B is in the pool.

Simple. Clean. Straight to the point.

---

### 🖥️ Why Frontends Love This

Imagine you're on a DEX website and you're about to make a swap.

The app needs to show you:

- How much liquidity is available
- What the current price ratio is
- How big your trade is compared to the pool size (to estimate slippage)

To do all that, the frontend needs to read the **current reserves** — and this function makes that easy.

Without it, the frontend would have to manually track every event and try to guess the state — which is error-prone and inefficient.

---

And that’s the core logic of a decentralized exchange.
You now understand:

- How swaps are calculated
- How liquidity works
- And how LP tokens represent ownership

Next: let’s test this out, add tokens, and make our first trade.

---

# 🧪 Testing Your AMM Contract on Remix

You’ve built a powerful AMM contract — now let’s see it in action.

To test it properly, you’ll need:

1. Two basic ERC-20 token contracts (Token A and Token B)
2. Your `AutomatedMarketMaker` contract
3. A few simple approvals and transactions

---

## 🧱 Step 1: Create Two ERC-20 Tokens

Go to https://remix.ethereum.org and open a new file named:

**`TokenA.sol`**

Paste this simple ERC-20 contract:

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20 {
    constructor() ERC20("Token A", "TKA") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Mint 1 million tokens to you
    }
}

```

Now create a second file named:

**`TokenB.sol`**

Paste this:

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenB is ERC20 {
    constructor() ERC20("Token B", "TKB") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

```

✅ **Compile both** using the Solidity compiler tab.

---

## 🧠 Step 2: Deploy Both Tokens

Switch to the **Deploy & Run** tab:

- Environment: `Remix VM (London)`
- Deploy `TokenA`
- Deploy `TokenB`

You now have two tokens, each with 1 million supply.

---

## 💧 Step 3: Deploy Your AMM Contract

Create a new file called **`AutomatedMarketMaker.sol`**

Paste your full AMM contract here (you already have it!).

Then go to the Deploy tab again and provide:

- `_tokenA`: Paste the address of your deployed `TokenA`
- `_tokenB`: Paste the address of your deployed `TokenB`
- `_name`: e.g., `"Liquidity Pool Token"`
- `_symbol`: e.g., `"LPT"`

👉 Click **Deploy** — your AMM contract is now live.

---

## ✅ Step 4: Approve Token Transfers

Before the AMM can move your tokens, you must give it **permission**.

ERC-20 tokens don’t let just anyone transfer your tokens — you must call `approve()` to authorize the AMM.

### For Token A:

1. Copy your AMM contract’s address.
2. Go to the deployed `TokenA` contract.
3. Call `approve(address spender, uint amount)`:
   - `spender`: paste the AMM address
   - `amount`: something big like `1000000000000000000000` (i.e., 1000 tokens, assuming 18 decimals)

### For Token B:

Do the exact same thing with your `TokenB` contract.

✅ Now your AMM contract is authorized to move your tokens on your behalf.

---

## 💧 Step 5: Add Liquidity

Now let’s add tokens to the pool.

1. Go to your deployed `AMM` contract.
2. Call `addLiquidity(uint256 amountA, uint256 amountB)`
   - If your tokens use 18 decimals (they do), then:
     - 100 tokens = `100000000000000000000` (add 18 zeroes)
   - Try `100 * 10^18` for both

Once done:

- You’ve officially added liquidity
- You’ll see LP tokens minted to your address
- An event will be emitted

---

## 🔁 Step 6: Try a Token Swap

Let’s say you want to trade 10 Token A for Token B:

1. Approve the AMM again for 10 Token A (if not already approved)
2. Call `swapAforB(uint256 amountAIn, uint256 minBOut)`
   - `amountAIn`: `10000000000000000000` (10 A tokens)
   - `minBOut`: try something like `1` for now, to avoid reverts

After the call:

- You’ll receive Token B in your wallet
- The reserves in the AMM will update

---

## 🔁 Reverse Swap: Token B → Token A

Same idea, just reversed:

1. Approve AMM to spend some Token B.
2. Call `swapBforA(amountBIn, minAOut)`

✅ Boom — you just traded using an AMM you wrote yourself.

---

## 🔙 Step 7: Remove Liquidity

1. Check your LP token balance with `balanceOf(your address)`
2. Call `removeLiquidity(uint liquidityToRemove)`
3. You’ll get your share of Token A and B back

---

## 🧪 Pro Tip: Watch Events

You’ll see logs like:

- `LiquidityAdded`
- `TokensSwapped`
- `LiquidityRemoved`

These help verify what happened — and are what real frontends use to update the UI.

---

## ✅ You Did It

You now:

- Deployed two ERC-20 tokens
- Built and tested your own AMM
- Swapped tokens using math instead of market makers
- And became the first liquidity provider to your own DEX

---

## 🎉 Wrap Up – You Just Built a DEX Engine

Take a second to appreciate what you’ve just done.

You didn’t just write another Solidity contract —

you built the **core engine** that powers platforms like **Uniswap**, **SushiSwap**, and dozens of other DeFi protocols.

Let’s recap what you accomplished:

---

### ✅ You Learned the Core of AMMs

- Why the old way of trading (order books) doesn’t work on-chain
- How AMMs flipped the game using simple math: `x * y = k`
- How liquidity pools work and why LP tokens matter
- How price discovery, slippage, and fees are baked right into the math

---

### ✍️ You Wrote the Full Smart Contract Logic

- You created an ERC-20-based AMM from scratch
- You supported **swapping**, **adding**, and **removing liquidity**
- You handled LP token minting, fee logic, and reserve tracking
- You used **utility functions** like `sqrt()` and `min()` to keep things fair and gas-efficient

---

### 🧪 You Ran It in Remix

- Deployed two tokens
- Launched your AMM
- Approved token transfers
- Added liquidity
- Performed real token swaps
- Watched everything update in real time

---

### 🎯 What You’ve Built

You now understand not just **how** AMMs work…

but how to actually **build one** — and that’s the kind of skill that sets you apart in the world of Web3.

You wrote a self-contained, self-sustaining smart contract that can:

- Manage liquidity
- Calculate fair swap prices
- Maintain balance
- And run forever on-chain

No middlemen. No permissions. Just code + math.
