# 🎉 Day 30 – The Final Build: Your Own Mini DEX

**You made it.**

Thirty full days of diving deep into Solidity. One contract at a time. One concept at a time. From your first `uint` to your first token sale, you’ve been showing up, building, learning — and now? You’re ready to create the thing that powers everything from DeFi whales to yield farming Degens:

A **Decentralized Exchange** — your own **Mini DEX**.

But before we go any further —

### 🧡 Let’s take a moment to appreciate this

Seriously. Look back at Day 1.

You started with basic storage, structs, and functions. You learned about global variables, control flow, modifiers, inheritance, and interfaces. You got hands-on with NFTs, DAOs, AMMs, stablecoins, oracles, randomness, upgradable contracts, and more.

And you didn’t just read about them —

**You built them.**

This wasn’t a read-and-forget kind of series.
This was: write, debug, understand, break, fix, and deploy.

That’s real Solidity muscle you’ve grown. And now, on Day 30, it’s time for your capstone:

### 🚀 A Mini Decentralized Exchange

Not a simulation. Not a copy-paste Uniswap clone. We’re talking a clean, simple, stripped-down, **from-scratch implementation** of a DEX — just enough to understand how swapping, liquidity, and LP tokens really work.

This isn’t frontend stuff. This is the **on-chain backend** of a DEX. The smart contract logic. The vault. The pool. The price curve.

And to make it all click, we’re splitting this final challenge into **two contracts**:

---

### 🛠️ `MiniDexPair.sol` – The Pool Contract

This is where the action happens:

- It takes in two tokens: TokenA and TokenB
- It allows users to **add liquidity**, and in return, they get LP tokens
- It allows users to **remove liquidity**, and get back their proportional share
- It enables **swaps** between TokenA and TokenB, using the classic constant product formula: `x * y = k`
- It keeps track of internal reserves, LP balances, and fees

This is the core logic that runs every token pair — whether it's ETH/DAI, USDC/WBTC, or any other combo.

We’ll go deep into how this works, how fees are calculated, and how reserve updates keep the pool balanced.

---

### 🏗️ `MiniDexFactory.sol` – The Pool Creator

Once we understand how a single pair contract works, we’ll take it to the next level.

Instead of manually deploying new pair contracts for every token combo, we’ll build a factory that:

- Can **create** new MiniDexPair contracts dynamically
- Keeps track of **all existing pairs**
- Ensures no duplicate pools
- Lets us explore how protocols like Uniswap can scale to thousands of pairs

By the end of this lesson, you’ll have:

- A working mini version of a decentralized exchange
- The ability to deploy any pair you want
- A full understanding of how swaps, reserves, LP tokens, and AMMs work under the hood

And more importantly?
You’ll realize that these seemingly complex protocols are just smart contract patterns, composed from tools you already know.

---

So. One last time.

Let’s write a contract. Let’s learn something real. And let’s end this journey with the same energy we started with:

**Builder mode on.**

Let’s dive into `MiniDexPair.sol`.

---

### 📦 The Core Pool: `MiniDexPair.sol`

Before we get into the *how*, let’s first see the *what*.

This is the **MiniDexPair** contract — the engine that powers every token swap in our Mini DEX.

It’s the vault. The liquidity pool. The LP token calculator.

It’s responsible for holding two tokens, letting people swap between them, and managing the internal reserves that keep the whole system fair and fluid.

You can think of this as your personal token exchange booth.

Put in TokenA, get out TokenB — priced automatically based on supply, demand, and some simple but powerful math.

We’ll break down every function in detail, but first, let’s take a look at the whole contract in one shot:

```solidity
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MiniDexPair is ReentrancyGuard {
    address public immutable tokenA;
    address public immutable tokenB;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLPSupply;

    mapping(address => uint256) public lpBalances;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
    event Swapped(address indexed user, address inputToken, uint256 inputAmount, address outputToken, uint256 outputAmount);

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "Identical tokens");
        require(_tokenA != address(0) && _tokenB != address(0), "Zero address");

        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // Utilities
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _updateReserves() private {
        reserveA = IERC20(tokenA).balanceOf(address(this));
        reserveB = IERC20(tokenB).balanceOf(address(this));
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 lpToMint;
        if (totalLPSupply == 0) {
            lpToMint = sqrt(amountA * amountB);
        } else {
            lpToMint = min(
                (amountA * totalLPSupply) / reserveA,
                (amountB * totalLPSupply) / reserveB
            );
        }

        require(lpToMint > 0, "Zero LP minted");

        lpBalances[msg.sender] += lpToMint;
        totalLPSupply += lpToMint;

        _updateReserves();

        emit LiquidityAdded(msg.sender, amountA, amountB, lpToMint);
    }

    function removeLiquidity(uint256 lpAmount) external nonReentrant {
        require(lpAmount > 0 && lpAmount <= lpBalances[msg.sender], "Invalid LP amount");

        uint256 amountA = (lpAmount * reserveA) / totalLPSupply;
        uint256 amountB = (lpAmount * reserveB) / totalLPSupply;

        lpBalances[msg.sender] -= lpAmount;
        totalLPSupply -= lpAmount;

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        _updateReserves();

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    function getAmountOut(uint256 inputAmount, address inputToken) public view returns (uint256 outputAmount) {
        require(inputToken == tokenA || inputToken == tokenB, "Invalid input token");

        bool isTokenA = inputToken == tokenA;
        (uint256 inputReserve, uint256 outputReserve) = isTokenA ? (reserveA, reserveB) : (reserveB, reserveA);

        uint256 inputWithFee = inputAmount * 997;
        uint256 numerator = inputWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputWithFee;

        outputAmount = numerator / denominator;
    }

    function swap(uint256 inputAmount, address inputToken) external nonReentrant {
        require(inputAmount > 0, "Zero input");
        require(inputToken == tokenA || inputToken == tokenB, "Invalid token");

        address outputToken = inputToken == tokenA ? tokenB : tokenA;
        uint256 outputAmount = getAmountOut(inputAmount, inputToken);

        require(outputAmount > 0, "Insufficient output");

        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        IERC20(outputToken).transfer(msg.sender, outputAmount);

        _updateReserves();

        emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);
    }

    // View functions
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function getLPBalance(address user) external view returns (uint256) {
        return lpBalances[user];
    }

    function getTotalLPSupply() external view returns (uint256) {
        return totalLPSupply;
    }
}
```

---

### 🧱 Let’s start at the top: the imports

Right off the bat, you’ll see this at the top of our `MiniDexPair` contract:

```solidity
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

```

Here’s what each one is doing:

---

### 📦 `IERC20.sol`

This brings in the **interface** for the ERC-20 token standard.

> In plain terms: it tells our contract how to talk to any ERC-20 token — even though we didn’t write the token’s code ourselves.
> 

With this interface, we can:

- Call `transferFrom`, `transfer`, and `balanceOf` on **any compliant ERC-20 token**
- Use those tokens inside our liquidity pool
- Stay fully token-agnostic — DAI, USDC, WETH, whatever — it all just works

Without this import, Solidity wouldn’t know how to talk to the token contracts you pass in.

---

### 🛡️ `ReentrancyGuard.sol`

This one is for **security**.

It helps us protect against a class of smart contract attacks called **reentrancy attacks** — where someone tries to call back into the contract *before the first function call is done*.

> Reentrancy is one of the most common and dangerous exploits in smart contract history — it’s what caused the infamous DAO hack.
> 

By inheriting `ReentrancyGuard`, we can use the `nonReentrant` modifier on sensitive functions like `addLiquidity`, `removeLiquidity`, and `swap`.

That ensures:

- One call at a time
- No funny business
- Your liquidity stays safe

---

Together, these two imports form the foundation of a safe, interoperable, ERC-20 powered DEX.

---

### 🧮 State Variables – The Pool’s Memory

Here’s the first block of state variables in our `MiniDexPair` contract:

```solidity
 
address public immutable tokenA;
address public immutable tokenB;

uint256 public reserveA;
uint256 public reserveB;
uint256 public totalLPSupply;

```

Let’s walk through them:

---

### `tokenA` and `tokenB`

```solidity
 
address public immutable tokenA;
address public immutable tokenB;

```

These are the **two tokens** that this specific DEX pair supports.

Each `MiniDexPair` contract will only ever deal with exactly two tokens.

For example:

- If this pool is for DAI/WETH, then `tokenA = DAI`, and `tokenB = WETH`.

They’re marked `public` so anyone can read them, and `immutable` because:

> Once set during the constructor, they can never be changed.
> 

`immutable` is a Solidity keyword that:

- Lets you assign a value **once** (inside the constructor)
- But **locks** that value forever afterward
- And is more **gas-efficient** than using regular `storage` variables

So: once these tokens are set, no one can ever swap them out or mess with them. Which is exactly what we want — pools should be permanent and predictable.

---

### `reserveA` and `reserveB`

```solidity
 
uint256 public reserveA;
uint256 public reserveB;

```

These track how much of each token is currently **in the pool**.

Whenever someone adds liquidity, does a swap, or removes liquidity, we update these reserves to reflect the new balances.

These are **not just the actual token balances** in the contract — we keep them stored separately for two reasons:

1. **Read efficiency** — it's faster and cheaper to reference variables than to keep calling `balanceOf`.
2. **Price accuracy** — we use them in swap calculations to ensure the constant product formula (`x * y = k`) stays balanced.

We’ll update these manually using `_updateReserves()` after each major action.

---

### `totalLPSupply`

```solidity
 
uint256 public totalLPSupply;

```

This tracks the **total amount of LP tokens** ever minted — kind of like the total shares of a company.

When someone adds liquidity, we mint LP tokens for them (not actual ERC-20 tokens in this case, just tracked internally).

When they remove liquidity, we burn their LP amount and reduce this total.

> LP tokens represent ownership of the pool. If you own 10% of the LP supply, you own 10% of the tokens in the pool.
> 

---

### 🧾 Tracking Who Owns What: `lpBalances`

```solidity
 
mapping(address => uint256) public lpBalances;
```

This mapping is how we keep track of **how much liquidity each user owns** in this pool.

Here’s how it works:

- The `address` is the wallet of the user (a liquidity provider).
- The `uint256` is how many LP tokens they’ve been allocated (again, these aren’t ERC-20 tokens — just a number we track inside the contract).

So if Alice adds DAI and WETH to this pool, we might have:

```solidity
 
lpBalances[alice] = 1200;

```

That means Alice has 1,200 LP tokens — which gives her a proportional claim on the tokens in the pool.

And when she decides to withdraw (remove liquidity), we’ll use this mapping to:

- Check how many LP tokens she has
- Calculate how much of TokenA and TokenB she’s entitled to
- Burn her LP balance and update the reserves accordingly

> Think of lpBalances as the pool’s version of a shareholder registry.
> 
> 
> It keeps the accounting honest and fair.
> 

Because it’s marked `public`, any user can check how much LP they have in the pool just by calling the `lpBalances(address)` function.

---

Together with the `totalLPSupply`, this mapping lets us implement all the math around **proportional ownership**.

---

### 📢 Events – Logging What Happens On-Chain

Here are the events declared in the `MiniDexPair` contract:

```solidity
 
event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
event Swapped(address indexed user, address inputToken, uint256 inputAmount, address outputToken, uint256 outputAmount);

```

Events are like **on-chain logs** — they don’t affect contract logic, but they make it easy to **track and index what’s happening** inside your contract.

You can think of them as console logs for smart contracts — except users, apps, explorers, and bots can all listen to them too.

Let’s go through them one by one:

---

### `LiquidityAdded`

```solidity
 
event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);

```

This event fires when someone adds liquidity to the pool.

It tells the world:

- Who added liquidity (`provider`)
- How much of each token they supplied (`amountA`, `amountB`)
- How many LP tokens they received in return (`lpMinted`)

The keyword `indexed` on `provider` means we can **filter logs by provider address** — super useful for frontends and analytics dashboards.

---

### `LiquidityRemoved`

```solidity
 
event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);

```

This one’s the mirror image of the previous event.

It fires when someone **removes liquidity** from the pool.

We log:

- Who removed liquidity
- How much of each token they withdrew
- How many LP tokens were burned

This gives everyone visibility into liquidity flows in and out of the pool.

---

### `Swapped`

```solidity
 
event Swapped(address indexed user, address inputToken, uint256 inputAmount, address outputToken, uint256 outputAmount);

```

This event logs every token **swap** that happens in the pool.

It includes:

- The address of the swapper
- What token they sent in (`inputToken`) and how much
- What token they got back (`outputToken`) and how much

This is the core data that DEX frontends, dashboards, and explorers need to **track real-time trading activity**.

> Every time someone uses the DEX to swap tokens, this event gets fired — letting the world know exactly what happened.
> 

---

Together, these events give us a complete **audit trail** of everything that happens in this pool:

- Liquidity flows
- Token swaps
- LP token issuance and burning

---

### 🏗️ The Constructor – Spinning Up a Pool

Here’s the constructor for `MiniDexPair`:

```solidity
 
constructor(address _tokenA, address _tokenB) {
    require(_tokenA != _tokenB, "Identical tokens");
    require(_tokenA != address(0) && _tokenB != address(0), "Zero address");

    tokenA = _tokenA;
    tokenB = _tokenB;
}

```

This function runs **only once**, right when the contract is deployed. It sets the identity of this specific pool — and locks in which two tokens it will support.

Let’s break it down:

---

```solidity
constructor(address _tokenA, address _tokenB)
```

We pass in the two token addresses this pool should support.

For example, if we want a WETH/DAI pool, we’d pass in the WETH and DAI contract addresses here.

---

```solidity
require(_tokenA != _tokenB, "Identical tokens");
```

This line ensures we’re not accidentally trying to create a pool for the same token twice — like WETH/WETH. That would be pointless.

---

```solidity
require(_tokenA != address(0) && _tokenB != address(0), "Zero address");
```

This check ensures we’re not using a null address for either token — which could cause errors or even security issues down the line.

---

```solidity
tokenA = _tokenA; tokenB = _tokenB;
```

Finally, we assign the input values to the contract’s `immutable` state variables.

> And because they’re immutable, they can only be set once — here in the constructor — and can never be changed afterward.
> 

This ensures that:

- Each contract instance is permanently tied to just two tokens
- Nobody can mess with the token addresses after deployment

---

Once this constructor runs, the pool is locked, secure, and ready to start taking deposits.

---

### 🛠️ Utility Functions – The Unsung Heroes Behind the Math

Before we get into the real action — swapping tokens, adding liquidity, minting LP tokens — we need a couple of mathematical sidekicks.

These two functions don’t directly touch tokens or users, but they’re **essential behind the scenes**.

They keep our numbers fair, our calculations safe, and our logic clean.

Here they are:

```solidity
 
function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
}

function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
}

```

Let’s talk about what each one does and where it shows up later in the contract:

---

### `sqrt(uint y)`

This is a square root calculator — implemented using the **Babylonian method**, a classic approach for estimating square roots in pure integer math.

Why do we need it?

We use this function when the **very first liquidity provider** enters the pool.

When there are no tokens in the reserves yet, we can’t use the usual proportional LP calculation.

Instead, we calculate the LP tokens to mint using the geometric mean of the token amounts they deposit:

```solidity
 
lpToMint = sqrt(amountA * amountB);

```

This gives the first provider a fair share based on both tokens — not just the larger one — and sets the tone for the pool’s initial ratio.

---

### `min(uint256 a, uint256 b)`

This one’s straightforward: it returns the smaller of the two inputs.

And we use it right after the pool has been initialized — when the pool has reserves and a user is adding liquidity.

To keep the pool ratio intact, we only consider the **smaller effective contribution** when minting LP tokens:

```solidity
 
lpToMint = min(
    (amountA * totalLPSupply) / reserveA,
    (amountB * totalLPSupply) / reserveB
);

```

That way:

- You can’t cheat the system by over-supplying one token
- LP tokens are only minted for the balanced portion of your deposit

---

Both of these helpers are small in size but big in impact.

Without them, the rest of the contract’s math would be clunky, repetitive, and error-prone.

---

### 🔄 `_updateReserves()` – Keeping the Numbers in Sync

Here’s the function:

```solidity
 
function _updateReserves() private {
    reserveA = IERC20(tokenA).balanceOf(address(this));
    reserveB = IERC20(tokenB).balanceOf(address(this));
}

```

This function is simple — but it plays a **key role** in maintaining the integrity of our pool.

Let’s break it down:

---

### What does it do?

It updates our internal tracking variables — `reserveA` and `reserveB` — by actually reading how many tokens are sitting in the contract:

```solidity
 
IERC20(tokenA).balanceOf(address(this));
IERC20(tokenB).balanceOf(address(this));

```

These are the **true balances** of each token held by the contract at any moment.

We store these values in the `reserveA` and `reserveB` state variables so we don’t have to keep calling `balanceOf` over and over again — which would cost more gas and clutter the code.

---

### Why is it marked `private`?

Because this function isn’t meant to be called directly by users or external contracts.

It’s an **internal helper** — used by functions like:

- `addLiquidity`
- `removeLiquidity`
- `swap`

Basically, any time tokens move in or out of the contract, we call `_updateReserves()` to sync up the numbers.

This keeps the internal state accurate and ensures that all our math (especially in swap calculations) is based on the **latest actual balances**.

---

Without this function, we’d risk:

- Calculating LP tokens based on outdated reserves
- Breaking the constant product formula
- Letting users front-run outdated pool data

So while it might be small and tucked away, `_updateReserves()` is the glue that keeps our pool honest.

---

### 💧 `addLiquidity()` – Supplying Tokens to the Pool

Before we can swap tokens or earn fees, the pool needs **liquidity**.

That means someone has to come in and deposit both tokens — TokenA and TokenB — to get the system rolling.

This function lets anyone do that.

Here’s the full code:

```solidity
 
function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant {
    require(amountA > 0 && amountB > 0, "Invalid amounts");

    IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
    IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

    uint256 lpToMint;
    if (totalLPSupply == 0) {
        lpToMint = sqrt(amountA * amountB);
    } else {
        lpToMint = min(
            (amountA * totalLPSupply) / reserveA,
            (amountB * totalLPSupply) / reserveB
        );
    }

    require(lpToMint > 0, "Zero LP minted");

    lpBalances[msg.sender] += lpToMint;
    totalLPSupply += lpToMint;

    _updateReserves();

    emit LiquidityAdded(msg.sender, amountA, amountB, lpToMint);
}

```

---

Let’s break it down step by step:

---

### Step 1: Basic checks

```solidity
 
require(amountA > 0 && amountB > 0, "Invalid amounts");

```

You can’t add zero tokens — both amounts need to be greater than zero for the function to proceed.

---

### Step 2: Pull in tokens

```solidity
 
IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

```

This pulls both tokens from the user’s wallet into the pool.

Note: the user must’ve called `approve()` beforehand for both tokens.

---

### Step 3: Determine how many LP tokens to mint

```solidity
 
uint256 lpToMint;
if (totalLPSupply == 0) {
    lpToMint = sqrt(amountA * amountB);
} else {
    lpToMint = min(
        (amountA * totalLPSupply) / reserveA,
        (amountB * totalLPSupply) / reserveB
    );
}

```

This is where the math kicks in.

- If it’s the **first-ever deposit**, we use `sqrt(amountA * amountB)` to set the initial LP supply.
- If it’s a **subsequent deposit**, we use the `min(...)` logic to ensure the liquidity is added in the correct ratio and LP tokens are minted proportionally.

This part keeps everything fair and prevents people from gaming the system by over-supplying one token.

---

### Step 4: Final checks and state updates

```solidity
 
require(lpToMint > 0, "Zero LP minted");
lpBalances[msg.sender] += lpToMint;
totalLPSupply += lpToMint;

```

We check that the LP amount isn’t zero, then:

- Add the new LP tokens to the user’s balance
- Increase the overall LP supply

---

### Step 5: Update reserves

```solidity
 
_updateReserves();

```

This syncs the pool’s internal state with the actual token balances, making sure all future math is based on up-to-date values.

---

### Step 6: Emit the event

```solidity
 
emit LiquidityAdded(msg.sender, amountA, amountB, lpToMint);

```

Fires an on-chain log so frontends, explorers, and analytics tools can track the liquidity action.

---

That’s the full flow:

From token deposit to LP minting to state update — all in one clean, protected function.

---

### 💸 `removeLiquidity()` – Withdrawing Your Share from the Pool

If you’ve added tokens to the pool and received LP tokens in return, you’ll eventually want to **cash out**.

This function lets liquidity providers withdraw their share of the pool — based on how many LP tokens they hold.

Here’s the complete function:

```solidity
 
function removeLiquidity(uint256 lpAmount) external nonReentrant {
    require(lpAmount > 0 && lpAmount <= lpBalances[msg.sender], "Invalid LP amount");

    uint256 amountA = (lpAmount * reserveA) / totalLPSupply;
    uint256 amountB = (lpAmount * reserveB) / totalLPSupply;

    lpBalances[msg.sender] -= lpAmount;
    totalLPSupply -= lpAmount;

    IERC20(tokenA).transfer(msg.sender, amountA);
    IERC20(tokenB).transfer(msg.sender, amountB);

    _updateReserves();

    emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
}

```

Let’s walk through what’s happening here:

---

### Step 1: Validate the LP tokens being burned

```solidity
 
require(lpAmount > 0 && lpAmount <= lpBalances[msg.sender], "Invalid LP amount");

```

We make sure:

- The user is actually trying to remove a **positive** amount
- They’re not trying to remove **more than they own**

---

### Step 2: Calculate how much of each token to return

```solidity
 
uint256 amountA = (lpAmount * reserveA) / totalLPSupply;
uint256 amountB = (lpAmount * reserveB) / totalLPSupply;

```

This is the proportional share formula.

If you own 10% of the LP supply, you should get 10% of both token reserves back.

That’s exactly what this math does — based on the current reserves and your LP balance.

---

### Step 3: Burn LP tokens

```solidity
 
lpBalances[msg.sender] -= lpAmount;
totalLPSupply -= lpAmount;

```

We update our internal tracking:

- The user’s LP balance goes down
- The total supply of LP tokens goes down as well

This simulates **burning** the LP tokens.

---

### Step 4: Transfer tokens back to the user

```solidity
 
IERC20(tokenA).transfer(msg.sender, amountA);
IERC20(tokenB).transfer(msg.sender, amountB);

```

Now that we know what the user is owed, we transfer both tokens back to them directly from the pool.

---

### Step 5: Sync the internal reserves

```solidity
 
_updateReserves();

```

Because tokens just left the pool, we need to update our internal `reserveA` and `reserveB` values to match reality.

---

### Step 6: Emit a log for transparency

```solidity
 
emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);

```

This event tells the outside world:

- Who removed liquidity
- How much of each token they got back
- How many LP tokens were burned

---

That’s it — with this function, liquidity providers can safely and fairly withdraw their share of the pool.

---

### 🔄 `getAmountOut()` – Calculating Swap Output

Before we actually perform a swap, we need to know:

**"If I give the pool X amount of TokenA, how much TokenB will I get back?"**

That’s exactly what this function does — it uses the **constant product formula** to calculate a fair output amount based on current reserves.

Here’s the function:

```solidity
 
function getAmountOut(uint256 inputAmount, address inputToken) public view returns (uint256 outputAmount) {
    require(inputToken == tokenA || inputToken == tokenB, "Invalid input token");

    bool isTokenA = inputToken == tokenA;
    (uint256 inputReserve, uint256 outputReserve) = isTokenA ? (reserveA, reserveB) : (reserveB, reserveA);

    uint256 inputWithFee = inputAmount * 997;
    uint256 numerator = inputWithFee * outputReserve;
    uint256 denominator = (inputReserve * 1000) + inputWithFee;

    outputAmount = numerator / denominator;
}

```

Let’s break it down:

---

### Step 1: Token validation

```solidity
 
require(inputToken == tokenA || inputToken == tokenB, "Invalid input token");

```

The user must be swapping either `tokenA` or `tokenB` — nothing else is accepted.

---

### Step 2: Identify the input and output sides of the trade

```solidity
 
bool isTokenA = inputToken == tokenA;
(uint256 inputReserve, uint256 outputReserve) = isTokenA ? (reserveA, reserveB) : (reserveB, reserveA);

```

We determine which direction the trade is going:

- If `inputToken == tokenA`, we’re swapping A → B
- Otherwise, we’re swapping B → A

Then we extract the correct reserves accordingly.

---

### Step 3: Apply the swap fee

```solidity
 
uint256 inputWithFee = inputAmount * 997;

```

We apply a **0.3% fee** — just like Uniswap V2 does.

- The full input amount would be `inputAmount * 1000`
- But we only use 997, keeping 0.3% inside the pool as protocol fee

This small fee makes DEX liquidity sustainable — rewarding LPs with swap fees.

---

### Step 4: Calculate output using the AMM formula

```solidity
 
uint256 numerator = inputWithFee * outputReserve;
uint256 denominator = (inputReserve * 1000) + inputWithFee;
outputAmount = numerator / denominator;

```

This is the **core formula** of a constant product AMM (`x * y = k`), rearranged to calculate output:

output=input×outputReserve×997inputReserve×1000+input×997\text{output} = \frac{\text{input} \times \text{outputReserve} \times 997}{\text{inputReserve} \times 1000 + \text{input} \times 997}

output=inputReserve×1000+input×997input×outputReserve×997

This ensures:

- The more you try to swap at once, the worse your price becomes (slippage)
- The pool never gets drained completely
- Swaps always leave the product `x * y` roughly the same

---

This function is read-only (`view`) — it doesn’t move any tokens.

It’s meant to **simulate** what a swap would yield before you actually do it.

---

### 🔁 `swap()` – Performing the Token Swap

This function lets users trade one token for the other — based on current pool reserves and the constant product formula.

Here’s the full function:

```solidity
 
function swap(uint256 inputAmount, address inputToken) external nonReentrant {
    require(inputAmount > 0, "Zero input");
    require(inputToken == tokenA || inputToken == tokenB, "Invalid token");

    address outputToken = inputToken == tokenA ? tokenB : tokenA;
    uint256 outputAmount = getAmountOut(inputAmount, inputToken);

    require(outputAmount > 0, "Insufficient output");

    IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
    IERC20(outputToken).transfer(msg.sender, outputAmount);

    _updateReserves();

    emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);
}

```

Let’s walk through how a swap works:

---

### Step 1: Input validation

```solidity
 
require(inputAmount > 0, "Zero input");
require(inputToken == tokenA || inputToken == tokenB, "Invalid token");

```

We make sure the user is sending:

- A non-zero amount
- One of the two valid pool tokens

No random token contracts allowed here.

---

### Step 2: Determine the output token

```solidity
 
address outputToken = inputToken == tokenA ? tokenB : tokenA;

```

If the input is TokenA, the output is TokenB — and vice versa.

We’re building a simple two-token pool, so this logic is always binary.

---

### Step 3: Calculate how much to send back

```solidity
 
uint256 outputAmount = getAmountOut(inputAmount, inputToken);
require(outputAmount > 0, "Insufficient output");

```

We call the `getAmountOut()` function we just broke down.

This uses the AMM formula and current reserves to calculate a fair price (including the 0.3% fee).

If the result is zero — maybe because the input was too small — we revert.

---

### Step 4: Transfer tokens

```solidity
 
IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
IERC20(outputToken).transfer(msg.sender, outputAmount);

```

Now we actually move tokens:

- Pull the input token from the user into the pool
- Send the calculated output token back to the user

This is the **real swap** in action.

---

### Step 5: Sync the reserves

```solidity
 
_updateReserves();

```

After tokens move, we call `_updateReserves()` to reflect the new pool state.

Without this, future swaps could break the math or become manipulable.

---

### Step 6: Emit a swap event

```solidity
 
emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);

```

This helps frontends and dashboards display swap activity — including slippage, volumes, and pair movements.

---

That’s the full swap logic — clean, fast, and secure.

You’ve now completed the entire logic for a working liquidity pool:

✅ Add liquidity

✅ Remove liquidity

✅ Calculate fair prices

✅ Execute token swaps

---

### 👀 View Functions – Reading the Pool’s State

Here they are:

```solidity
 
function getReserves() external view returns (uint256, uint256) {
    return (reserveA, reserveB);
}

function getLPBalance(address user) external view returns (uint256) {
    return lpBalances[user];
}

function getTotalLPSupply() external view returns (uint256) {
    return totalLPSupply;
}

```

Let’s quickly walk through what each one does:

---

### `getReserves()`

```solidity
 
function getReserves() external view returns (uint256, uint256)

```

This returns the current amount of **TokenA and TokenB** in the pool — according to the internal tracking variables `reserveA` and `reserveB`.

Useful for:

- Frontends showing the current state of the pool
- Users calculating expected swap prices or slippage
- Verifying the actual liquidity available

---

### `getLPBalance(address user)`

```solidity
 
function getLPBalance(address user) external view returns (uint256)

```

This tells you **how many LP tokens** a given address holds — essentially their **ownership stake** in the pool.

Useful for:

- Letting users check how much liquidity they’ve provided
- Building LP dashboards
- Calculating how much they’d get back on withdrawal

---

### `getTotalLPSupply()`

```solidity
 
function getTotalLPSupply() external view returns (uint256)

```

Returns the total number of LP tokens ever minted — which equals the sum of all individual LP balances.

This helps:

- Maintain accurate proportional math
- Check how much of the pool any single LP owns (via `user LP / total LP`)
- Visualize how the pool is growing over time

---

And with that, the `MiniDexPair` contract is **complete**.

You now have a fully working DEX pair:

- Supports ERC-20 tokens
- Lets users swap, add, and remove liquidity
- Calculates prices using a constant product AMM model
- Emits clean events and exposes helpful view functions

---

## 🧰 Running `MiniDexPair` in Remix – Step-by-Step

### ✅ Prerequisites

Before we dive in:

1. Open Remix IDE
2. Make sure you’re using **Solidity version 0.8.20** or higher
3. Install or import **2 ERC-20 mock tokens** (we’ll create these for demo purposes)

---

### 🧪 Step 1: Create two mock ERC-20 tokens

We need two tokens to simulate a swap pair — let’s call them `TokenA` and `TokenB`.

Here’s a super simple ERC-20 implementation you can use for both:

```solidity
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

```

Deploy **two** of these with different names, symbols, and large initial supplies (e.g., `1_000_000 ether`) — one for `TokenA`, and one for `TokenB`.

---

### 🏗️ Step 2: Deploy the MiniDexPair contract

Now paste in your `MiniDexPair` contract, compile it, and deploy it by passing the two token addresses from Step 1:

```solidity
 
new MiniDexPair(TokenA_address, TokenB_address)

```

This initializes the pair contract to only accept those two specific tokens.

---

### 💰 Step 3: Approve the pair contract to spend tokens

Before calling `addLiquidity`, your tokens need permission to be transferred.

Call the `approve()` function on both token contracts (via Remix UI):

```solidity
 
TokenA.approve(MiniDexPair_address, amount)
TokenB.approve(MiniDexPair_address, amount)

```

Use a big number like `1000000000000000000000` (which is `1000 * 10^18` for tokens with 18 decimals).

---

### ➕ Step 4: Add liquidity

Now call:

```solidity
 
addLiquidity(amountA, amountB)

```

For example:

```solidity
 
addLiquidity(1000 ether, 2000 ether)

```

This will deposit the tokens and mint LP tokens to your wallet.

Use `getReserves()` and `getLPBalance(yourAddress)` to verify the results.

---

### 🔁 Step 5: Swap tokens

Now try calling `swap` from another address (or the same one), after approving it again:

```solidity
 
swap(500 ether, TokenA_address)

```

This should send in TokenA and give you TokenB based on the current pool ratio.

Use `getAmountOut(inputAmount, inputToken)` to preview the result before you swap.

---

### 💸 Step 6: Remove liquidity

To get your tokens back, just call:

```solidity
 
removeLiquidity(lpAmount)

```

You can use `getLPBalance(yourAddress)` to find your exact LP holdings and pass that in.

You should receive both tokens back, minus the pool fee effects from any previous swaps.

---

### 📊 Step 7: Track what’s happening

Use the Remix “Logs” panel to observe:

- `LiquidityAdded`
- `LiquidityRemoved`
- `Swapped`

You can also use the read-only view functions to check:

- `getReserves()`
- `getTotalLPSupply()`
- `getLPBalance(address)`

---

That’s it — you just deployed and ran your own mini Uniswap-style pool using Remix.

---

### 🏗️ Let’s Make It Dynamic – Enter the `MiniDexFactory`

Up until now, our `MiniDexPair` contract has been solid — it works beautifully as a standalone pool.

But here’s the catch:

Every time we want to create a new token pair — say `WETH/USDC`, `DAI/FRAX`, or `PEPE/SOL` — we’d have to manually deploy a fresh copy of the `MiniDexPair` contract.

And that’s fine if you’re building a one-off prototype.

But in the real world of DeFi, DEXs don’t support **just one** trading pair.

They support **hundreds**, sometimes **thousands**, and all of them need to be:

- Deployable on the fly
- Discoverable and indexable
- Reusable by other contracts and frontends

So what do we do?

> We introduce a Factory — a smart contract that can deploy new pools, track them, and make the whole DEX system dynamic.
> 

That’s exactly what `MiniDexFactory` does.

This contract becomes the **central registry** of all the pairs in our DEX.

With it, we can:

- Create new token pairs **on demand**
- Prevent duplicates
- Retrieve the address of a pair using just the token addresses
- Loop through all pairs if needed (for analytics, UIs, etc.)

In short, this is how we scale from a one-pool prototype to a **fully functioning decentralized exchange**.

---

### 🧱 The Full `MiniDexFactory` Contract – The Launchpad for Pools

Now that we’ve built and tested a single `MiniDexPair`, it’s time to **scale**.

This contract right here — `MiniDexFactory` — is the backbone of our DEX system. It’s the part that lets us **dynamically create new liquidity pools** for any pair of tokens, whenever we need.

Here’s the high-level logic:

- Only the contract owner can create new pairs (for now)
- When `createPair()` is called, it spins up a new `MiniDexPair` with the given tokens
- It stores that pair’s address in a mapping so we can fetch it later
- It makes sure **no duplicate pairs** get created (e.g., `DAI/WETH` and `WETH/DAI` should be treated the same)
- And it logs everything with a `PairCreated` event

In short: this is the part of the DEX that grows with you.

Here’s the complete code:

```solidity
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MiniDexPair.sol"; // Assumes MiniDexPair.sol is in the same directory

contract MiniDexFactory is Ownable {
    event PairCreated(address indexed tokenA, address indexed tokenB, address pairAddress, uint);

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor(address _owner) Ownable(_owner) {}

    function createPair(address _tokenA, address _tokenB) external onlyOwner returns (address pair) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");
        require(_tokenA != _tokenB, "Identical tokens");
        require(getPair[_tokenA][_tokenB] == address(0), "Pair already exists");

        // Sort tokens for consistency
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

        pair = address(new MiniDexPair(token0, token1));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length - 1);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function getPairAtIndex(uint index) external view returns (address) {
        require(index < allPairs.length, "Index out of bounds");
        return allPairs[index];
    }
}

```

---

### 📦 Imports – Bringing in the Tools We Need

```solidity
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MiniDexPair.sol"; // Assumes MiniDexPair.sol is in the same directory

```

These two lines set up everything the `MiniDexFactory` needs to function safely and efficiently.

Let’s look at each one:

---

### `Ownable.sol`

This import comes from **OpenZeppelin**, and it gives our contract **access control**.

By inheriting from `Ownable`, we can:

- Automatically track the contract’s `owner`
- Restrict sensitive functions like `createPair()` to only be callable by the owner
- Use the `onlyOwner` modifier for security

In other words, we’re making sure **not just anyone** can start creating new token pairs — unless you decide to loosen it later.

---

### `MiniDexPair.sol`

This is our own local import — it brings in the **pair contract** we wrote earlier.

> The factory’s whole job is to deploy new instances of this contract for different token combinations.
> 

So anytime we call `createPair()`, we’ll be spinning up a fresh `MiniDexPair`, passing in the two token addresses we want the pool to support.

The key point here is:

The factory *knows about* the pair contract and uses it as a template — kind of like minting a new pool every time someone needs a new trading pair.

---

### 🏗️ Contract Declaration

```solidity
 
contract MiniDexFactory is Ownable {

```

This line defines the name of our contract and the fact that it inherits from OpenZeppelin’s `Ownable` contract. Let’s unpack both parts:

---

```solidity
MiniDexFactory
```

This is the **blueprint** for a DEX manager — a smart contract that can:

- Deploy multiple liquidity pool contracts (`MiniDexPair`)
- Keep track of them
- Make sure no duplicate pools get created

You can think of this as the **backend admin** of your decentralized exchange — it doesn’t do the swapping, but it keeps everything organized.

---

```solidity
is Ownable
```

This gives our contract an **owner** — and with it, access to the `onlyOwner` modifier.

That means:

- Only the contract deployer (or someone the deployer transfers ownership to) can call functions like `createPair()`
- We add a basic layer of **access control** and **security**, especially useful during initial setup or while testing

This helps prevent random users from spamming pool creation — though in a production-grade system, you might later open this up with proper validation.

---

So with just this one line, we’ve set up a contract that:

- Can deploy new pair contracts
- Owns the authority to control how and when pools are created

---

### 🧠 How Does the Factory Track Everything?

If this contract is going to be the central hub for pool creation, it needs a reliable way to **track**, **store**, and **expose** the data behind every MiniDex pair.

We need to:

- Log when new pairs are created
- Let users or frontends query any pair by token addresses
- Keep a full list of all created pairs for analytics or indexing

That’s exactly what this section handles.

Here’s the code that makes all of that possible:

```solidity
 
event PairCreated(address indexed tokenA, address indexed tokenB, address pairAddress, uint);

mapping(address => mapping(address => address)) public getPair;
address[] public allPairs;

```

### `event PairCreated(...)`

This event fires every time a new pair is created via `createPair()`.

```solidity
 
event PairCreated(address indexed tokenA, address indexed tokenB, address pairAddress, uint);

```

Here’s what each part logs:

- `tokenA` and `tokenB`: the two tokens in the pair (indexed so you can filter by them)
- `pairAddress`: the actual deployed address of the new `MiniDexPair` contract
- A `uint` that acts as the pair’s index in the `allPairs` array

This is incredibly useful for:

- Frontend apps trying to display all available pairs
- Indexers tracking pair creation on-chain
- Developers debugging deployments

---

### `mapping getPair`

```solidity
 
mapping(address => mapping(address => address)) public getPair;

```

This is a **double mapping** used to store the deployed address of every pair that gets created.

You can think of it like a lookup table:

```solidity
 
getPair[DAI][WETH] = 0x...PairAddress
getPair[WETH][DAI] = 0x...SamePairAddress

```

Both directions are stored so users can query the pair regardless of token order — more on that in the `createPair()` function.

And because it’s marked `public`, Solidity automatically creates a getter function for it.

You can call `getPair(tokenA, tokenB)` at any time to check whether that pair exists and retrieve the deployed pool address.

---

### `address[] public allPairs`

This array stores **all the pair contracts** ever created by this factory.

Each time a new pool is created, it gets pushed into this array.

It allows:

- Looping through all created pools
- Returning pool addresses by index
- Building paginated UIs and analytics dashboards

We’ll use this in functions like `allPairsLength()` and `getPairAtIndex()`.

---

So with just these three lines, we’ve built:

- A way to **log** every new pair
- A way to **store** and **look up** each one efficiently
- A way to **list and count** every pool in the system

---

### 🏁 Constructor – Setting the Owner

```solidity
 
constructor(address _owner) Ownable(_owner) {}

```

This constructor does one simple but important thing: it sets the **initial owner** of the factory contract.

Let’s unpack it:

- We accept an `_owner` address as input during deployment.
- We pass that address directly to the `Ownable` constructor from OpenZeppelin.

The result?

Whoever deploys the contract can **assign ownership to someone else immediately** — instead of always defaulting to the deployer.

That’s handy if:

- You’re deploying the contract on behalf of a DAO or frontend
- You want ownership to go to a multisig, a timelock, or some other contract

By making ownership flexible from the start, we keep things more composable and production-friendly.

Now that we’ve initialized the owner, let’s look at the star of the show: the `createPair()` function.

---

### 🛠️ `createPair()` – Deploying a New Liquidity Pool

This function allows the factory to **deploy a brand-new MiniDexPair contract** for any two tokens — as long as they haven’t already been paired.

Here’s the full code:

```solidity
 
function createPair(address _tokenA, address _tokenB) external onlyOwner returns (address pair) {
    require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");
    require(_tokenA != _tokenB, "Identical tokens");
    require(getPair[_tokenA][_tokenB] == address(0), "Pair already exists");

    // Sort tokens for consistency
    (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

    pair = address(new MiniDexPair(token0, token1));
    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair;

    allPairs.push(pair);
    emit PairCreated(token0, token1, pair, allPairs.length - 1);
}

```

Let’s break it down step by step:

---

### 🔒 Access Control

```solidity
 
external onlyOwner

```

Only the **owner of the factory** (set in the constructor) can call this function.

This prevents just anyone from spamming new pools — though in a public DEX, you might eventually relax this restriction.

---

### 🧼 Basic Validations

```solidity
 
require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");
require(_tokenA != _tokenB, "Identical tokens");
require(getPair[_tokenA][_tokenB] == address(0), "Pair already exists");

```

We make sure:

- Both token addresses are valid
- The tokens aren’t the same
- A pair for this combination doesn’t already exist

This keeps things clean, safe, and avoids duplicates.

---

### 🧭 Token Sorting

```solidity
 
(address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

```

This is subtle but **very important**.

We always store pairs in the order `(token0, token1)` where `token0 < token1`.

This ensures:

- We treat `DAI/WETH` and `WETH/DAI` as the **same** pair
- Our mapping works in both directions
- Frontends and indexers don’t get confused

---

### 🧱 Deploy the Pair Contract

```solidity
 
pair = address(new MiniDexPair(token0, token1));

```

We create a new instance of the `MiniDexPair` contract using the sorted tokens.

This is the actual **on-chain liquidity pool**.

---

### 🧾 Store the Pair

```solidity
 
getPair[token0][token1] = pair;
getPair[token1][token0] = pair;
allPairs.push(pair);

```

We:

- Store the pair address in the mapping under both combinations
- Add the pair to our `allPairs` array so it can be indexed

---

### 📢 Emit Event

```solidity
 
emit PairCreated(token0, token1, pair, allPairs.length - 1);

```

Finally, we emit a `PairCreated` event so anyone listening (frontends, explorers, bots) knows that a new pool was created.

---

And that’s it — a full on-chain **pair factory**.

---

### 👀 View Functions – Exploring the Factory

These functions don’t modify anything — they’re purely for **reading** the list of pools the factory has created.

Here’s the code:

```solidity
 
function allPairsLength() external view returns (uint) {
    return allPairs.length;
}

function getPairAtIndex(uint index) external view returns (address) {
    require(index < allPairs.length, "Index out of bounds");
    return allPairs[index];
}

```

Let’s break them down:

---

### `allPairsLength()`

This is a simple way to get the **total number of pairs** created by the factory.

Useful for:

- Frontend pagination (e.g., “Page 1 of X pairs”)
- Indexers looping through all existing pools
- Protocol analytics or dashboards

---

### `getPairAtIndex(index)`

This function lets you retrieve a specific pair contract by its position in the list.

For example:

```solidity
 
getPairAtIndex(0)

```

Might return the first pool ever created — like `DAI/WETH`.

We also include a `require` check to make sure the index is valid, preventing accidental out-of-bounds errors.

---

Together, these view functions make it easy to **browse, fetch, and interact** with all MiniDex pairs deployed via the factory.

And that’s it — your factory is now a full-fledged, dynamic pool manager.

---

## 🧪 How to Run MiniDexFactory + MiniDexPair in Remix

### ✅ Step 0: Open Remix and Set Up Your Environment

1. Go to Remix IDE
2. Ensure the compiler is set to **Solidity 0.8.20** or higher
3. Create **three files**:
    - `MockToken.sol`
    - `MiniDexPair.sol`
    - `MiniDexFactory.sol`

Paste the respective contract code into each.

---

### 🧱 Step 1: Deploy Two Mock ERC-20 Tokens

In `MockToken.sol`, paste:

```solidity
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

```

Compile and deploy **two tokens**, for example:

- TokenA: `("Token A", "TKA", 1000000 ether)`
- TokenB: `("Token B", "TKB", 1000000 ether)`

Keep note of their addresses.

---

### 🏭 Step 2: Deploy `MiniDexFactory`

In `MiniDexFactory.sol`, make sure it imports `MiniDexPair.sol`, then compile and deploy the factory:

```solidity
 
new MiniDexFactory(msg.sender)

```

This gives ownership of the factory to your current account in Remix.

---

### ⚙️ Step 3: Create a Pool Using the Factory

Call:

```solidity
 
createPair(TokenA_address, TokenB_address)

```

The factory will:

- Deploy a new MiniDexPair contract
- Save it in its registry
- Emit a `PairCreated` event

To get the new pair address:

- Call `getPair(tokenA, tokenB)`
- Or use `getPairAtIndex(0)`

---

### 📋 Step 4: Interact With the Deployed Pair

Now that the pool exists:

1. Copy the pair address from the factory
2. Go to the "Deploy & Run" panel in Remix
3. Under "At Address", paste the pair address and select `MiniDexPair` as the contract

You can now interact directly with the pool!

---

### 🔑 Step 5: Approve the Pair Contract to Spend Tokens

From the **MockToken contract(s)**:

- Call `approve(pairAddress, amount)` for **both tokens**

You must approve before you can `addLiquidity`.

---

### 💧 Step 6: Add Liquidity

From the `MiniDexPair` instance, call:

```solidity
 
addLiquidity(amountA, amountB)

```

For example:

```solidity
 
addLiquidity(1000 ether, 2000 ether)

```

Then verify:

- Your LP balance: `getLPBalance(yourAddress)`
- Current reserves: `getReserves()`

---

### 🔁 Step 7: Try a Swap

From the same pair contract:

1. Approve again from a second account (or the same one)
2. Call:

```solidity
 
swap(inputAmount, inputToken)

```

Use `getAmountOut()` first to see what you’ll get.

---

### 💸 Step 8: Remove Liquidity

Call:

```solidity
 
removeLiquidity(lpAmount)

```

This sends back your proportional share of both tokens.

---

### 🔍 Step 9: Explore and Monitor

Use:

- `getPair(tokenA, tokenB)` to fetch any pool
- `allPairsLength()` to count them
- `getPairAtIndex(index)` to loop through all pools
- Remix logs to view all events