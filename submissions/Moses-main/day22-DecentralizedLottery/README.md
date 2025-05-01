# DecentralisedLottery contract

Welcome back to **30 Days of Solidity** — where every day, we level up our smart contract game.

So far, you’ve already pulled off some pretty cool stuff:

- You made contracts that **send and receive ETH**,
- Protected them with **modifiers** like digital bouncers,
- Fortified your code against shady tricks like **reentrancy attacks**,
- And even brought digital art to life with your own **NFTs**.

But today?

Today we step beyond the walls of our contract.

We’re tapping into the _real world_ — a world where smart contracts can reach out, ask for data, and bring it back **securely**.

And we’re doing it in style…

By building a **decentralized lottery**.

Not just any lottery.

This one’s:

- 🧾 **Provably fair**
- ⚙️ **Fully automated**
- 🔐 **Impossible to rig**

And at the heart of it is something special:

**Chainlink VRF** — a trusted source of randomness that works on-chain.

---

## 🔮 But Wait… What Even _Is_ Chainlink VRF?

Here’s the catch:

Smart contracts are brilliant… but they’re also **predictable**.

They’ll only ever do what’s written in the code — and nothing more.

That means they **can’t generate randomness**.

And in a lottery? That’s kind of a dealbreaker.

If you try to use stuff like timestamps or block numbers as randomness, miners can **manipulate** them.

That’s where **Chainlink VRF** comes in.

Think of it like this:

You call in a trusted referee, hand them a sealed envelope, and say:

> “Flip a coin. Show everyone the result. Then lock it into the blockchain.”

That’s what Chainlink VRF does.

It gives you:

- 🎲 A **random number**,
- 🧾 A **cryptographic proof** that it was generated fairly,
- 📦 And it delivers both directly to your smart contract.

This is how we bring **trusted randomness** into an **untrusting world**.

And now that you know what’s behind the curtain…

Let’s build a lottery that _actually deserves_ to be called fair.

---

## 🧾 Full Contract – FairChainLottery

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }
    LOTTERY_STATE public lotteryState;

    address payable[] public players;
    address public recentWinner;
    uint256 public entryFee;

    // Chainlink VRF config
    uint256 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    uint256 public latestRequestId;

    constructor(
        address vrfCoordinator,
        uint256 _subscriptionId,
        bytes32 _keyHash,
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value >= entryFee, "Not enough ETH");
        players.push(payable(msg.sender));
    }

    function startLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    function endLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        lotteryState = LOTTERY_STATE.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
            )
        });

        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");

        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];
        recentWinner = winner;

        players = new address payable ;
        lotteryState = LOTTERY_STATE.CLOSED;

        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH to winner");
    }

    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}

```

---

Alright — you’ve learned **why** we need randomness, you’ve met our referee (_Chainlink VRF_), and now it’s time to **build the actual game**.

But this isn’t some dusty old raffle box.

We’re building a **tamper-proof**, **automated**, **on-chain lottery system** that anyone can enter… and **no one** can cheat.

At the end of each round, the contract will ask Chainlink for a random number, pick one lucky winner from the pool, and **send them all the ETH**.

No human hands. No behind-the-scenes tricks.

Just math, transparency, and a little bit of Chainlink magic.

---

## 🔗 Chainlink Setup

Before we can spin our lottery wheel, we need a way to get **true randomness** into our contract — and that’s where **Chainlink VRF** comes into play.

But to actually use Chainlink’s randomness system, we need to _talk_ to it. And in Solidity, that means importing the right libraries — sort of like plugging in a smart contract version of a walkie-talkie that lets our lottery chat with Chainlink’s oracle network.

Here’s how we do that:

```solidity

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

```

These imports give us two main tools:

1. **`VRFConsumerBaseV2Plus`** – This is a _base contract_ provided by Chainlink. We inherit from it, and in return, we get a special function called `fulfillRandomWords` that Chainlink automatically calls when the random number is ready. Think of it as the “callback” slot for the random number.
2. **`VRFV2PlusClient`** – This is a helper library that gives us an easy way to structure and format the randomness request we send to Chainlink. It lets us configure things like:
   - How many random numbers we want
   - How much gas to use for the callback
   - Which Chainlink job to use (via `keyHash`)

Together, these two pieces are **our direct link to randomness** on-chain. Without them, we wouldn’t be able to securely reach out to the outside world.

---

## 🏗️ Let’s Declare Our Contract

With our Chainlink setup ready, it’s time to actually declare the smart contract that will run the show.

Here’s the start of our decentralized lottery system:

```solidity

contract FairChainLottery is VRFConsumerBaseV2Plus {

```

We’re calling it `FairChainLottery` — because that’s exactly what we’re building:

A **lottery contract that lives on-chain**, and **fairness is baked right into its DNA**.

Notice that we’re inheriting from `VRFConsumerBaseV2Plus` — this is what gives our contract the ability to receive random numbers from Chainlink and use them inside our logic.

---

From here, we’ll start defining the variables and functions that make the whole lottery system tick — from tracking who’s entered to crowning a winner and sending them the entire prize pool.

Let’s dive deeper 👇

---

## 🧠 Lottery States – Keeping the Game in Check

Every good system needs rules.

And in the case of our lottery, we need to be **crystal clear** about what phase the contract is in — because different things should be allowed at different times.

Are we letting players join?

Are we waiting for a winner to be picked?

Or are we just chilling between rounds?

That’s where this little piece of code comes in:

```solidity

enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }
LOTTERY_STATE public lotteryState;

```

Let’s break it down.

---

```jsx
enum LOTTERY_STATE
```

An `enum` is short for **enumeration**, and in Solidity, it’s a way of creating a list of named states that a variable can take.

In this case, we’ve defined three possible states for our lottery:

- `OPEN` – The lottery is live and **players can enter**.
- `CLOSED` – The lottery is **inactive**. No entries, no picks. Just chill.
- `CALCULATING` – The lottery is currently **asking Chainlink for a random number**, and **no one can enter or restart the game** until we get the result.

---

### 📍 Why This Matters

This `lotteryState` variable is the **contract's brain** — it helps us manage the flow of the game and enforce the right rules at the right time.

For example:

- We only allow new players to enter when `lotteryState == OPEN`
- We only start a new round if the state is `CLOSED`
- We only pick a winner if we’re in the `CALCULATING` state

This prevents:

- People from sneaking in late during winner selection
- Accidentally starting a new round in the middle of another
- Repeated randomness requests (which would be expensive and chaotic)

---

## 👥 Player Tracking

```solidity

address payable[] public players;
address public recentWinner;
uint256 public entryFee;

```

- `players` stores everyone who joined this round.
- `recentWinner` remembers who won the last round.
- `entryFee` sets how much ETH someone has to pay to join.

---

###

## ⚙️ Chainlink Config – Wiring Up the Randomness Engine

When we ask Chainlink for a random number, we don’t just say:

> “Hey, give me something random.”

Nope — we have to be very **specific** about how we want it.

That’s where this set of configuration variables comes in:

```solidity

uint256 public subscriptionId;
bytes32 public keyHash;
uint32 public callbackGasLimit = 100000;
uint16 public requestConfirmations = 3;
uint32 public numWords = 1;
uint256 public latestRequestId;

```

Let’s walk through what each of these does, and why it matters.

---

```jsx
subscriptionId;
```

This is like your **Chainlink account ID** — it’s tied to your Chainlink subscription, which you fund with LINK tokens to pay for oracle services.

Any time you make a randomness request, LINK gets deducted from your subscription.

This ID tells the Chainlink coordinator:

> “Charge it to my tab.”

---

```jsx
keyHash;
```

This identifies **which Chainlink oracle job** you want to run.

Think of Chainlink having many different “jobs” — each one powered by different oracles with different configurations (some faster, some more decentralized, etc.).

The `keyHash` is a unique identifier that says:

> “Use this specific configuration of the VRF service.”

It ensures you're connecting to the **right oracle setup** for your needs.

---

```jsx
callbackGasLimit;
```

This sets a **gas budget** for Chainlink when it calls your contract back with the result.

Chainlink has to invoke your `fulfillRandomWords()` function to deliver the random number.

And just like any other transaction, it needs gas.

This number tells Chainlink:

> “You’re allowed to use up to X gas when fulfilling the request.”

Too low? Your function might fail.

Too high? You’re wasting gas.

So you want to find a nice middle ground — 100,000 is usually a good safe default for simple logic like winner selection.

---

```jsx
requestConfirmations;
```

This sets **how many block confirmations** Chainlink waits for before generating your random number.

Why?

Because the more confirmations you wait for, the **harder it becomes to manipulate** the result (even by miners).

It adds **security**, but also adds a slight **delay**.

A value like `3` is a solid balance between speed and security.

---

```jsx
numWords;
```

This tells Chainlink how many **random numbers** you want in one request.

We're just picking one winner here, so `1` is enough.

But if you were doing something like shuffling a list, selecting multiple winners, or generating NFT traits, you could ask for more.

---

```jsx
latestRequestId;
```

Every time you make a randomness request, Chainlink gives you a **request ID**.

We store it here, mainly for tracking purposes — for example, in a frontend or if we wanted to verify responses.

You can think of it like a ticket number for your randomness order.

---

## 🛠️ Constructor – Setting Up the Game Room

Alright, before we let anyone enter the lottery, we need to **set the table**.

Just like how you’d prepare for a real-world lottery — printing tickets, locking the prize pool, and setting entry prices — we need to **initialize our smart contract with the right setup**.

That’s what the **constructor** is for.

Here’s the code:

```solidity

constructor(
    address vrfCoordinator,
    uint256 _subscriptionId,
    bytes32 _keyHash,
    uint256 _entryFee
) VRFConsumerBaseV2Plus(vrfCoordinator) {
    subscriptionId = _subscriptionId;
    keyHash = _keyHash;
    entryFee = _entryFee;
    lotteryState = LOTTERY_STATE.CLOSED;
}

```

Let’s unpack what’s happening here:

---

### 🧩 Constructor Basics

In Solidity, a `constructor` is a **special function** that runs **only once** — when the contract is first deployed.

It’s your one chance to **set the initial conditions** and lock in important values.

---

### 🧭 Parameter Breakdown

- **`vrfCoordinator`** – This is the address of Chainlink’s VRF Coordinator on the blockchain you’re deploying to. It acts as the middleman that receives randomness requests and returns the results.
- **`_subscriptionId`** – This is your Chainlink subscription ID (used for paying for VRF requests).
- **`_keyHash`** – This defines which randomness job Chainlink should use.
- **`_entryFee`** – This sets how much ETH a player must pay to join each round of the lottery.

---

### ⚙️ Initialization

Inside the body of the constructor, we’re doing a few key things:

```solidity

subscriptionId = _subscriptionId;
keyHash = _keyHash;
entryFee = _entryFee;
lotteryState = LOTTERY_STATE.CLOSED;

```

Here’s what that means:

- We're saving the **Chainlink config** passed to us during deployment.
- We're storing the **entry fee** as a state variable so it can be reused in the `enter()` function.
- And most importantly, we’re setting the `lotteryState` to `CLOSED` by default.

Why start it closed?

Because we want **control**.

We don’t want players entering while we’re still setting things up or before the lottery is officially started.

So we keep the doors shut — and later, the owner can call `startLottery()` to open the gates.

---

###

## 🚪 Enter the Lottery – Step Right Up!

Alright — the setup is done, the doors are open, and the neon sign is glowing: **“Lottery In Progress.”**

Now it’s time for people to start lining up and buying their tickets.

Let’s look at the function that makes that happen:

```solidity

function enter() public payable {
    require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
    require(msg.value >= entryFee, "Not enough ETH");
    players.push(payable(msg.sender));
}

```

---

### 🎟️ What’s Going On Here?

This function is your **ticket booth**. It allows any user on the blockchain to participate in the lottery, as long as they follow the rules.

Let’s go line by line:

---

```jsx
require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
```

We only allow people to enter when the lottery is in the `OPEN` state.

This protects the system from latecomers trying to sneak in during winner selection or setup.

If the lottery is still `CLOSED` or currently `CALCULATING`, this line will block the transaction.

It's like showing up to a closed carnival — the gates just won’t budge.

---

```jsx
require(msg.value >= entryFee, "Not enough ETH");
```

Next, we check that the player has paid **at least** the minimum required ETH.

The `msg.value` is the amount of ETH sent along with the transaction.

If it's less than the `entryFee`, the transaction is reverted with a polite (but firm) message:

> "Not enough ETH."

No free rides here.

---

```jsx
players.push(payable(msg.sender));
```

And finally — if all checks pass — we **add the player to the list**.

We wrap `msg.sender` in `payable(...)` because we're planning to potentially send ETH back to this address later (if they win). Solidity needs us to mark it as `payable` in order to transfer funds to it.

---

## 🟢 Start the Game – Let the Raffle Begin!

Before any tickets ae sold...

Before any ETH is collected...

Someone has to officially kick things off.

That someone? **The contract owner** — the one who deployed the contract.

Here’s the function that flips the switch:

```solidity

function startLottery() external onlyOwner {
    require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");
    lotteryState = LOTTERY_STATE.OPEN;
}

```

---

### `onlyOwner` – One Button, One Boss

The `onlyOwner` modifier (inherited from Chainlink’s base contract) makes sure that **only the person who deployed the contract** can call this function.

That means random players can’t:

- Start new rounds
- Mess with the lottery’s flow
- Break the game by restarting it mid-round

It’s like giving the power to fire the starting gun to the race coordinator — not the runners.

---

```jsx
require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");
```

This line ensures we’re not starting a round **while another one is already happening**.

In other words:

- You can’t open the gates if they’re already open.
- You can’t restart the lottery if it’s still waiting for Chainlink to return a winner.

This avoids messy overlaps and protects the flow of the game.

---

```jsx
lotteryState = LOTTERY_STATE.OPEN;
```

And now — with all the checks passed — we flip the switch.

The contract updates its state from `CLOSED` to `OPEN`, and just like that…

**The game begins.**

Players can now start entering the lottery by sending ETH to the contract.

---

## End the Game & Request Randomness – The Final Whistle

Once enough players have joined and it’s time to wrap things up, someone needs to officially end the game and ask Chainlink to roll the dice.

That’s what this function does:

```solidity

function endLottery() external onlyOwner {
    require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
    lotteryState = LOTTERY_STATE.CALCULATING;

    VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
        keyHash: keyHash,
        subId: subscriptionId,
        requestConfirmations: requestConfirmations,
        callbackGasLimit: callbackGasLimit,
        numWords: numWords,
        extraArgs: VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
        )
    });

    latestRequestId = s_vrfCoordinator.requestRandomWords(req);
}

```

---

### 🧠 What’s Happening Here?

Let’s break it down step by step:

---

```jsx
require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
```

We only want to end the lottery if it's currently active.

This check ensures someone doesn’t accidentally (or maliciously) end a round that hasn’t even started.

---

```jsx
lotteryState = LOTTERY_STATE.CALCULATING;
```

As soon as we end the round, we flip the state to `CALCULATING`.

This signals that we’re in the process of picking a winner and that no new players can enter right now.

---

### 🔮 Building the Request

This is where the real magic starts:

```solidity
    VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
        keyHash: keyHash,
        subId: subscriptionId,
        requestConfirmations: requestConfirmations,
        callbackGasLimit: callbackGasLimit,
        numWords: numWords,
        extraArgs: VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
        )
    });

```

We’re crafting a **randomness request** to send to Chainlink.

This object tells Chainlink everything it needs to know:

- Which randomness job to use (`keyHash`)
- Who’s paying (`subscriptionId`)
- How many confirmations to wait for
- How much gas to use when it responds
- How many random numbers we want (in this case, just `1`)

---

### 📡 Sending the Request

```solidity

latestRequestId = s_vrfCoordinator.requestRandomWords(req);

```

This line actually **sends the request to Chainlink VRF**.

At this point, our job is done — and the contract waits for Chainlink to respond with a random number.

Here’s the cool part: **we don’t call the next function manually.**

---

## 🏆 fulfillRandomWords – Automatically Called by Chainlink

Once Chainlink receives our request and does its cryptographic magic, it sends the result directly back to our contract by calling this function:

```solidity

function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
    require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");

    uint256 winnerIndex = randomWords[0] % players.length;
    address payable winner = players[winnerIndex];
    recentWinner = winner;

    players = new address payable ;
    lotteryState = LOTTERY_STATE.CLOSED;

    (bool sent, ) = winner.call{value: address(this).balance}("");
    require(sent, "Failed to send ETH to winner");
}

```

---

###

---

### 🛑 Safety Check

```solidity

require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");

```

Just to be safe, we double-check that the contract is indeed in the process of selecting a winner.

No funny business allowed here.

---

### 🧮 Picking the Winner

```solidity

uint256 winnerIndex = randomWords[0] % players.length;
address payable winner = players[winnerIndex];

```

We use the random number provided by Chainlink and apply the **modulo operator (`%`)** to make sure it maps to one of the player indexes.

Let’s say:

- We have 5 players
- Chainlink gives us `482340923`

Then:

```solidity

winnerIndex = 482340923 % 5 = 3

```

Boom — the 4th player in the list wins.

---

### 🎉 Declaring the Winner

```solidity

recentWinner = winner;

```

We store the winner’s address for reference, maybe to display in the UI or log later.

---

### 🧼 Resetting for the Next Round

```solidity

players = new address payable ;
lotteryState = LOTTERY_STATE.CLOSED;

```

We clear the players list and close the lottery — resetting the system so the owner can start a fresh round when ready.

---

### 💸 Sending the Prize

```solidity

(bool sent, ) = winner.call{value: address(this).balance}("");
require(sent, "Failed to send ETH to winner");

```

Finally, we send **all the ETH** stored in the contract to the lucky winner.

If the transfer fails for some reason, we revert to avoid any inconsistencies.

---

### 📬 Automatic Chainlink Magic

To be clear:

- We **manually call** `endLottery()` to send the randomness request.
- But we **don’t call** `fulfillRandomWords()` ourselves — Chainlink does that for us **automatically** when it returns the random number.

That’s the beauty of how oracles interact with smart contracts — **event-driven programming** at its finest.

---

## 🧾 Utility Function

```solidity
    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
```

This just returns the list of current players. Useful for frontend apps or explorers.

---

## 🧪 Running the Contract (on Base Sepolia with Chainlink VRF)

We’ve written a provably fair lottery, integrated Chainlink VRF, and walked through all the logic.

Now it’s time to **deploy and test it live**.

Let’s go step by step 👇

---

### 🌍 Step 1: Set Up Remix + MetaMask

1. **Open Remix IDE**
2. In MetaMask, **switch to the “Base Sepolia” network**.
   - You can add Base Sepolia to MetaMask via [Chainlist](https://chainlist.org/) or manually:
     - **RPC**: `https://sepolia.base.org`
     - **Chain ID**: `84532`
     - **Currency symbol**: ETH
     - **Explorer**: `https://sepolia.basescan.org`
3. In Remix, **go to the “Deploy & Run Transactions” tab**
4. Set **“Environment” to “Injected Provider - MetaMask”**

Now Remix is talking directly to your wallet on Base Sepolia ✅

---

### ⛽ Step 2: Get Test ETH on Base Sepolia

To interact with the contract, you’ll need some test ETH.

1. Get Sepolia ETH from Chainlink Faucet
2. Bridge to Base Sepolia using Base Bridge or use direct Base Sepolia faucets if available.

> ⚠️ Base Sepolia faucets can be rate-limited — be patient or use a devnet alternative.

---

### 🔑 Step 3: Subscribe to Chainlink VRF

Chainlink VRF requires a **subscription** to pay for random number requests.

Here’s how to create and fund one:

1. Go to Chainlink VRF Subscription Manager
2. Connect your wallet and switch to **Base Sepolia**
3. Click **"Create Subscription"**
4. Note the **Subscription ID** (you’ll need this for deployment)
5. Click **“Add Funds”** and deposit **LINK tokens**
   - You can get testnet LINK from the faucet on the same page

> ⚠️ Make sure you have LINK on Base Sepolia, not on Ethereum Sepolia.

---

### 👤 Step 4: Add Your Contract as a Consumer

Once your contract is deployed, you’ll need to **authorize it to use your VRF subscription**.

1. Copy your contract address after deploying
2. Go back to the VRF Subscription page
3. Click **“Add Consumer”**
4. Paste your contract address

Done! Now your contract is allowed to request randomness using your subscription ✅

---

### 🧱 Step 5: Deploy the Contract in Remix

1. In Remix, compile your contract
2. Go to the **Deploy & Run Transactions** tab
3. Enter the following in the constructor fields:
   - `vrfCoordinator`: Base Sepolia VRF coordinator address
     > 0x2ed832ba0d0969071f133b3f07f2f79c37f511f1
   - `subscriptionId`: (from the Chainlink VRF UI)
   - `keyHash`: The job you want to use
     > 0xc17251dcf7c0358d32be3324e9b61fb71c71ff0b245f78b45f87838f19d3f01d (Base Sepolia default key hash)
   - `entryFee`: E.g., `1000000000000000` for 0.001 ETH

Click **“Deploy”**, and confirm the MetaMask transaction.

---

### 🎮 Step 6: Interact With the Contract

Now that it’s deployed:

- 🟢 Call `startLottery()` (onlyOwner)
- 🧍 Anyone can `enter()` the lottery (send ETH > entryFee)
- 🛑 When ready, call `endLottery()` (onlyOwner) to request randomness
- 🧙 Chainlink will call `fulfillRandomWords()` automatically
- 🏆 Check `recentWinner` to see who won
- 🔄 Call `getPlayers()` to view current round’s participants

##

## 🧠 What You Just Mastered

You didn’t just build a lottery contract —

You just took your first big step into the world of **real-world smart contract interaction**.

Here’s what you now have under your belt:

- ✅ How to **integrate Chainlink VRF** to bring **secure, verifiable randomness** on-chain
- ✅ How to design a **stateful contract** using `enum` to manage game flow
- ✅ How to **handle ETH safely** — collecting it, storing it, and sending it back
- ✅ How to build contracts that **react to external events**, like oracle responses

---

This was your second taste of **off-chain to on-chain magic** — where your smart contract doesn’t just live in isolation, but actually talks to the outside world.

With Chainlink VRF, you now have a trustworthy way to add randomness into your dApps — and this is just the beginning.

You can take this concept and build:

- 🎮 Blockchain games with random loot drops
- 🎲 Dice rolls, card games, and turn-based mechanics
- 🧬 NFT minting with randomized traits
- 📦 Mystery boxes and raffles
- 🗳️ Fair DAO proposals with random jury selection

And way more.
