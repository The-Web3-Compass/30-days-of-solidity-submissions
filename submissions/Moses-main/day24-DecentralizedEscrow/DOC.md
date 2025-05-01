# DecentraliseEscrow Contract

Welcome back to **30 Days of Solidity**, where every day we take one step closer to mastering smart contracts — not just in theory, but in practice.

Today, we’re building something **real**. Something **practical**. Something that could literally be used in real-world marketplaces.

An **escrow service**.

---

### Wait — What Even Is Escrow?

If you've ever bought something expensive online — maybe a freelance job, a second-hand gadget, or a ticket — you’ve probably wished there was some middleman to hold the money until _everyone’s happy_.

That’s what **escrow** is all about.

In the real world, companies like PayPal or eBay do this for you. They hold your money until the item arrives. If things go wrong, they step in.

But in Web3? We don’t need those companies.

We can **code the middleman** — and make it trustless.

---

### What We’re Building

This contract, `EnhancedSimpleEscrow`, is a secure smart contract that:

- Holds ETH until the buyer confirms delivery
- Lets either party raise a dispute if things go wrong
- Allows a neutral **arbiter** to step in and resolve issues
- Has built-in **timeout logic** so the buyer isn’t left hanging forever
- Supports **mutual cancellation** if both parties agree to call it off

No paperwork. No waiting. No shady third party.

Just clear rules — written in Solidity.

---

This project teaches you how to:

- Use enums to manage contract states
- Handle timeouts using `block.timestamp`
- Implement dispute resolution workflows
- Use modifiers like `require()` for strict access control
- And make your contract frontend-ready with clean events and read-only functions

By the end of this, you’ll have built a **real working escrow system** that could power digital marketplaces, freelance platforms, NFT trades, and more.

Let’s dive in and write the rules of trust… with code.

## 🔐 EnhancedSimpleEscrow – A Smart Contract Middleman

Escrow services are one of the most practical use cases of blockchain. And today, you’re going to build one from scratch.

This smart contract acts like a **digital middleman**. It securely holds ETH while two parties — a **buyer** and a **seller** — complete a transaction. If something goes wrong, a trusted **arbiter** can step in to resolve the dispute.

It’s trustless, secure, and runs exactly as written — no surprises.

Here’s the full contract first:

---

## 🧾 Full Contract Code: `EnhancedSimpleEscrow.sol`

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title EnhancedSimpleEscrow - A secure escrow contract with timeout, cancellation, and events
contract EnhancedSimpleEscrow {
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;

    uint256 public amount;
    EscrowState public state;
    uint256 public depositTime;
    uint256 public deliveryTimeout; // Duration in seconds after deposit

    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
        deliveryTimeout = _deliveryTimeout;
    }

    receive() external payable {
        revert("Direct payments not allowed");
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(state == EscrowState.AWAITING_PAYMENT, "Already paid");
        require(msg.value > 0, "Amount must be greater than zero");

        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        emit PaymentDeposited(buyer, amount);
    }

    function confirmDelivery() external {
        require(msg.sender == buyer, "Only buyer can confirm");
        require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");

        state = EscrowState.COMPLETE;
        payable(seller).transfer(amount);
        emit DeliveryConfirmed(buyer, seller, amount);
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(state == EscrowState.AWAITING_DELIVERY, "Can't dispute now");

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter, "Only arbiter can resolve");
        require(state == EscrowState.DISPUTED, "No dispute to resolve");

        state = EscrowState.COMPLETE;
        if (_releaseToSeller) {
            payable(seller).transfer(amount);
            emit DisputeResolved(arbiter, seller, amount);
        } else {
            payable(buyer).transfer(amount);
            emit DisputeResolved(arbiter, buyer, amount);
        }
    }

    function cancelAfterTimeout() external {
        require(msg.sender == buyer, "Only buyer can trigger timeout cancellation");
        require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel in current state");
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");

        state = EscrowState.CANCELLED;
        payable(buyer).transfer(address(this).balance);
        emit EscrowCancelled(buyer);
        emit DeliveryTimeoutReached(buyer);
    }

    function cancelMutual() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(
            state == EscrowState.AWAITING_DELIVERY || state == EscrowState.AWAITING_PAYMENT,
            "Cannot cancel now"
        );

        EscrowState previousState = state;
        state = EscrowState.CANCELLED;

        if (previousState == EscrowState.AWAITING_DELIVERY) {
            payable(buyer).transfer(address(this).balance);
        }

        emit EscrowCancelled(msg.sender);
    }

    function getTimeLeft() external view returns (uint256) {
        if (state != EscrowState.AWAITING_DELIVERY) return 0;
        if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        return (depositTime + deliveryTimeout) - block.timestamp;
    }
}

```

---

## 🔖 Contract Name

```solidity

contract EnhancedSimpleEscrow {

```

We’re calling it **EnhancedSimpleEscrow** because it builds on a basic escrow idea — and adds features like dispute handling, timeout-based cancellation, and frontend-friendly events.

---

## 🧠 State Variables and Setup

Let’s explore the contract’s brain — the variables that hold all the important data.

### Parties Involved:

```solidity

address public immutable buyer;
address public immutable seller;
address public immutable arbiter;

```

These are the three fixed addresses set at the time of contract deployment.

- The **buyer** is the one sending the money
- The **seller** is the one delivering the goods or service
- The **arbiter** is the trusted third party who resolves disputes

---

### Escrow State Management:

```solidity

enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }
EscrowState public state;

```

We use an `enum` to track which phase the transaction is in. This makes the flow **easier to reason about and safer to use**.

---

### Amount and Timing:

```solidity

uint256 public amount;
uint256 public depositTime;
uint256 public deliveryTimeout;

```

- `amount` is the ETH locked in escrow
- `depositTime` tracks when the buyer made the payment
- `deliveryTimeout` is the window (in seconds) the seller has to deliver

---

### Events:

The contract emits events for every key action: deposits, confirmations, disputes, cancellations. This makes the contract **easy to hook into with a frontend** or monitoring tools.

```jsx
    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);
    event EscrowCancelled(address indexed initiator);
    event DeliveryTimeoutReached(address indexed buyer);
```

These events are like **broadcasts** — they get picked up by frontends, indexers, or analytics dashboards and trigger visual feedback like:

- "Payment received!"
- "Escrow completed!"
- "Dispute raised!"

Let’s go over each one.

---

### 1. `PaymentDeposited`

```solidity

event PaymentDeposited(address indexed buyer, uint256 amount);

```

Fires when the buyer successfully deposits ETH into escrow.

Used to:

- Confirm that escrow has started
- Show the locked amount in the frontend

---

### 2. `DeliveryConfirmed`

```solidity

event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);

```

Fires when the buyer confirms they’ve received the product or service.

Used to:

- Confirm completion of the transaction
- Indicate that the seller has been paid

---

### 3. `DisputeRaised`

```solidity

event DisputeRaised(address indexed initiator);

```

Fires when either the buyer or seller raises a dispute.

Used to:

- Notify the frontend and possibly trigger a UI change (like "Dispute in progress")
- Let the arbiter know their attention is needed

---

### 4. `DisputeResolved`

```solidity

event DisputeResolved(address indexed arbiter, address recipient, uint256 amount);

```

Fires when the arbiter resolves a dispute and funds are transferred.

Used to:

- Show final status of the dispute
- Display who got the funds and how much

---

### 5. `EscrowCancelled`

```solidity

event EscrowCancelled(address indexed initiator);

```

Fires when the escrow is cancelled, either through timeout or mutual agreement.

Used to:

- Update UI with "Escrow cancelled" status
- Indicate refund has been issued

---

### 6. `DeliveryTimeoutReached`

```solidity

event DeliveryTimeoutReached(address indexed buyer);

```

Fires if the buyer cancels after the delivery window expires.

Used to:

- Show timeout reason
- Explain why funds were refunded automatically

# 🔧 Functions – Bringing the Escrow Logic to Life

Alright, we’ve set up the players. We’ve defined the rules. We’ve got all our variables, states, and events in place.

Now it’s time to bring this escrow system to life — through **functions**.

Functions are where all the **action** happens.

They’re the buttons users press, the rules the contract enforces, and the logic that ensures funds move _only when conditions are met_.

In this contract, every step of the escrow process is clearly mapped out:

- The **buyer deposits** ETH into escrow
- The **seller delivers** and the buyer confirms
- If there’s trouble, either party can **raise a dispute**
- A neutral **arbiter steps in** to resolve conflicts
- The **buyer can cancel** if the seller takes too long
- And either side can **mutually walk away**

Each of these steps is handled by a dedicated function.

We’ll look at every one of them — in full — and **decode what each line is doing** so it’s not just something you copy-paste, but something you fully understand.

Let’s start from the beginning, with the very first thing that runs: the `constructor()`.

Ready? Let’s dive in.

# 🔨 `constructor` – Setting Up the Escrow

```solidity

constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
    require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");
    buyer = msg.sender;
    seller = _seller;
    arbiter = _arbiter;
    state = EscrowState.AWAITING_PAYMENT;
    deliveryTimeout = _deliveryTimeout;
}

```

### 🧠 What is a Constructor?

In Solidity, a `constructor` is a **special function** that runs **only once** — when the contract is first deployed.

It’s like the setup phase of the contract. This is where we define **who's involved**, **how long things should take**, and what the **starting state** of the system should be.

---

### 🚀 What This Constructor Does

When the buyer (the person deploying the contract) calls this constructor, they provide:

- The **seller’s** address (the person delivering the goods or service)
- The **arbiter’s** address (a neutral third party who can resolve disputes)
- A **delivery timeout** — how long the seller has to deliver before the buyer can cancel

This function then sets everything up for the escrow to begin.

---

### 🔍 Line-by-Line Breakdown

### 1. ✅ Timeout Must Be Set

```solidity

require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");

```

This is a basic safety check. We make sure the delivery timeout is a **positive number**.

Why? Because if it were 0, the buyer could instantly cancel the escrow the moment they deposit funds — which defeats the whole point of giving the seller time to deliver.

---

### 2. 👤 Set the Buyer

```solidity

buyer = msg.sender;

```

The buyer is the one **deploying the contract**, and `msg.sender` always refers to the person calling the function — in this case, the deployer.

That’s why we assign them as the buyer here.

They’re the one initiating the deal and responsible for locking in the funds.

---

### 3. 📦 Assign the Seller

```solidity

seller = _seller;

```

The address of the seller is passed in as a parameter during deployment.

This is the person who will eventually receive the funds _if_ the delivery is confirmed.

---

### 4. ⚖️ Set the Arbiter

```solidity

arbiter = _arbiter;

```

Again, passed in during deployment. The arbiter is the neutral judge.

They only get involved **if** something goes wrong — like if the buyer raises a dispute and claims the delivery wasn’t made.

The arbiter has the power to resolve the issue by releasing the funds to the buyer or seller.

---

### 5. 🕓 Set Initial State

```solidity

state = EscrowState.AWAITING_PAYMENT;

```

We start the contract in a **waiting state** — funds haven’t been deposited yet.

This ensures that the `deposit()` function is the next logical step, and any other action (like confirming delivery) is blocked until that happens.

---

### 6. ⏱️ Set the Timeout Window

```solidity

deliveryTimeout = _deliveryTimeout;

```

This sets the time window the seller has to deliver, measured in seconds.

It starts ticking only **after** the buyer deposits ETH into the contract.

We’ll later use this in the `cancelAfterTimeout()` function to let the buyer cancel the deal and get a refund if the seller delays.

---

##

# 🚫 `receive()` – Block Random ETH Transfers

```solidity

receive() external payable {
    revert("Direct payments not allowed");
}

```

### 🔍 What This Function Does

This little function is here to act as a **bouncer at the door** of your contract.

It blocks **any ETH** that someone tries to send **without calling the correct function** — like `deposit()`.

You might be wondering:

> Why do we need this at all?
>
> Isn’t all ETH sent to a contract just part of the normal flow?

Not exactly.

---

### 📬 The Hidden Behavior in Solidity

By default, any smart contract in Solidity can **receive ETH silently** — even if the sender doesn’t call a specific function.

That means someone could go to Etherscan, paste in your contract address, and send ETH to it _without_ interacting with your carefully written logic.

That’s where the `receive()` function comes in.

---

### 🧱 The Purpose of `receive()`

In Solidity, this special function is called **automatically** whenever the contract receives ETH **without any data**.

So if someone just sends ETH using:

- A wallet app like MetaMask
- Etherscan’s “Send ETH” button
- A raw transaction

...this function gets triggered.

But in our escrow system, we **don’t want that**.

We want every deposit to go through the proper channel — the `deposit()` function — where we:

- Track who sent it
- Update the `amount`
- Change the `state`
- Record the timestamp
- Emit an event

All of that is skipped if someone sends ETH blindly.

So instead, we **reject it**:

```solidity

revert("Direct payments not allowed");

```

This makes sure no ETH can accidentally enter the contract without proper handling.

No unexpected deposits. No state corruption. No user confusion.

---

# 💸 `deposit()` – Buyer Sends Funds to Escrow

```solidity

function deposit() external payable {
    require(msg.sender == buyer, "Only buyer can deposit");
    require(state == EscrowState.AWAITING_PAYMENT, "Already paid");
    require(msg.value > 0, "Amount must be greater than zero");

    amount = msg.value;
    state = EscrowState.AWAITING_DELIVERY;
    depositTime = block.timestamp;
    emit PaymentDeposited(buyer, amount);
}

```

### 🧠 What This Function Does

This is the **first real action** in our escrow contract.

Once the contract has been deployed and all three roles (buyer, seller, arbiter) are in place, this function allows the **buyer to lock ETH into the contract**.

This ETH is now in limbo — safely held by the smart contract — until the buyer confirms delivery, or a dispute is resolved.

Let’s break it down line by line.

---

### 🔐 Step 1: Only the Buyer Can Deposit

```solidity

require(msg.sender == buyer, "Only buyer can deposit");

```

We use `require()` to enforce that **only the buyer** (the one who deployed the contract) can call this function.

This prevents random users from interacting with the escrow and sending ETH that the contract isn’t expecting — keeping everything clean and secure.

---

### 🔁 Step 2: Only if Payment Hasn’t Been Made Yet

```solidity

require(state == EscrowState.AWAITING_PAYMENT, "Already paid");

```

Once the buyer has sent ETH, we move into a new state: `AWAITING_DELIVERY`.

This check ensures the `deposit()` function can only be called **once** — we don’t want people topping up the same escrow or sending ETH after it has already begun.

---

### 💰 Step 3: ETH Must Be Greater Than Zero

```solidity

require(msg.value > 0, "Amount must be greater than zero");

```

Just a basic safety check — you can’t send 0 ETH and expect the escrow to start.

Without this, someone could accidentally trigger the function with no funds, leaving the contract in a weird state.

---

### 🏦 Step 4: Lock the Funds

```solidity

amount = msg.value;

```

This stores the ETH that was sent into the contract in a state variable called `amount`.

We’ll later use this value to know **how much** to send to the seller (or refund to the buyer) once the escrow is completed or cancelled.

---

### 🔄 Step 5: Change the Contract State

```solidity

state = EscrowState.AWAITING_DELIVERY;

```

Once the money is in, we move to the next phase: we’re now waiting for the seller to deliver the item or service.

This also means other functions (like confirming delivery or raising a dispute) are now allowed — but only because we’re in the correct state.

---

### ⏱️ Step 6: Record the Timestamp

```solidity

depositTime = block.timestamp;

```

This saves the exact moment the ETH was deposited.

Why is this important?

We’ll use this in the `cancelAfterTimeout()` function later. If the seller doesn’t deliver within the time window (`deliveryTimeout`), the buyer can cancel and get their money back — **but only after this deposit time**.

---

### 📣 Step 7: Announce the Deposit

```solidity

emit PaymentDeposited(buyer, amount);

```

Events are how we tell the outside world what just happened.

This line triggers an on-chain event saying:

> “The buyer just deposited X ETH into escrow.”

Frontends and tools like Etherscan can listen to this and update the UI in real time.

---

##

# ✅ `confirmDelivery()` – Buyer Marks the Deal Complete

```solidity

function confirmDelivery() external {
    require(msg.sender == buyer, "Only buyer can confirm");
    require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");

    state = EscrowState.COMPLETE;
    payable(seller).transfer(amount);
    emit DeliveryConfirmed(buyer, seller, amount);
}

```

### 🧠 What This Function Does

Once the seller has delivered what was promised — whether it’s a physical item, a digital file, a service, or anything else — the buyer needs a way to say:

> “Yes, I’ve received it. Go ahead and release the funds.”

That’s exactly what this function does.

It **finalizes the transaction**, transfers the locked ETH to the seller, and updates the contract to show that everything is done.

Let’s walk through each line.

---

### 🧍 Step 1: Only the Buyer Can Confirm

```solidity

require(msg.sender == buyer, "Only buyer can confirm");

```

This ensures that **only the person who paid** — the buyer — can mark the transaction as complete.

We don’t want the seller or any other random user confirming the delivery prematurely.

The power to approve the release of funds stays strictly with the buyer.

---

### 🔒 Step 2: Only Allowed During the Delivery Window

```solidity

require(state == EscrowState.AWAITING_DELIVERY, "Not in delivery state");

```

We make sure the contract is currently waiting for delivery.

If we’re still waiting for a deposit, or the transaction has already been disputed, cancelled, or completed — this action is not allowed.

> This protects the flow of the escrow and prevents logic bugs or double confirmations.

---

### 🔁 Step 3: Change State to Complete

```solidity

state = EscrowState.COMPLETE;

```

We update the state to show that the deal is done.

From here on, no more deposits, disputes, or cancellations can happen. The escrow is officially over.

---

### 💸 Step 4: Release the Funds to the Seller

```solidity

payable(seller).transfer(amount);

```

This line **transfers the ETH** that was previously locked in the contract directly to the seller’s wallet.

We use `payable()` to explicitly say that this address is allowed to receive ETH.

The `amount` variable was set earlier when the buyer deposited, so we’re now sending exactly what was agreed upon.

> At this point, the seller has been paid, and the buyer has confirmed receipt. Trustless and automatic.

---

### 📣 Step 5: Emit the Delivery Confirmation Event

```solidity

emit DeliveryConfirmed(buyer, seller, amount);

```

This tells the outside world — your frontend, Etherscan, logs, notifications — that the escrow was completed successfully.

It includes:

- Who the buyer was
- Who the seller was
- How much ETH was sent

This makes it super easy to track on-chain activity and update the UI.

---

##

# ⚠️ `raiseDispute()` – Buyer or Seller Flags a Problem

```solidity

function raiseDispute() external {
    require(msg.sender == buyer || msg.sender == seller, "Not authorized");
    require(state == EscrowState.AWAITING_DELIVERY, "Can't dispute now");

    state = EscrowState.DISPUTED;
    emit DisputeRaised(msg.sender);
}

```

### 🧠 What This Function Does

Escrow transactions don’t always go smoothly.

Maybe the **seller didn’t deliver**.

Maybe the **buyer is claiming they didn’t receive the item**, even though the seller says they did.

When trust breaks down, we need a way for either party to **raise their hand and say: “Something’s wrong.”**

That’s what `raiseDispute()` is for.

It puts the escrow in a **disputed state** — where no funds can be moved — and signals the arbiter that their attention is needed.

Let’s break it down line by line.

---

### 👥 Step 1: Only the Buyer or Seller Can Call This

```solidity

require(msg.sender == buyer || msg.sender == seller, "Not authorized");

```

This function is **strictly limited** to the two parties involved in the deal — the buyer and the seller.

Random users can’t interfere.

The arbiter also isn’t allowed to trigger a dispute — they only resolve it.

This keeps the dispute system **clean, secure, and fair**.

---

### 🕒 Step 2: Only During the Delivery Phase

```solidity

require(state == EscrowState.AWAITING_DELIVERY, "Can't dispute now");

```

Disputes can only be raised **while the delivery is still pending**.

If the deal is already complete, cancelled, or disputed, this function is no longer allowed.

This ensures the dispute process happens at the **right time**, and prevents anyone from causing issues after the fact.

---

### 🔁 Step 3: Enter the Disputed State

```solidity

state = EscrowState.DISPUTED;

```

This is the heart of the function. It transitions the contract into a **locked** state where no ETH can be moved — not to the seller, and not back to the buyer.

It’s like saying:

> “Stop everything. We need a human (the arbiter) to step in and make a call.”

This ensures neither party can game the system while the conflict is unresolved.

---

### 📣 Step 4: Emit the Dispute Event

```solidity

emit DisputeRaised(msg.sender);

```

This tells the outside world — and especially the arbiter — that something is wrong.

We include `msg.sender` so we know **who raised the dispute** (buyer or seller), which can be useful for frontend feedback or notifications.

---

# ⚖️ `resolveDispute()` – Arbiter Decides the Outcome

```solidity

function resolveDispute(bool _releaseToSeller) external {
    require(msg.sender == arbiter, "Only arbiter can resolve");
    require(state == EscrowState.DISPUTED, "No dispute to resolve");

    state = EscrowState.COMPLETE;
    if (_releaseToSeller) {
        payable(seller).transfer(amount);
        emit DisputeResolved(arbiter, seller, amount);
    } else {
        payable(buyer).transfer(amount);
        emit DisputeResolved(arbiter, buyer, amount);
    }
}

```

### 🧠 What This Function Does

Once a dispute is raised using `raiseDispute()`, the escrow is frozen — no one can touch the funds until someone neutral steps in.

That neutral party is the **arbiter**.

The arbiter’s job is to review the situation and make a final decision:

**Should the seller get paid, or should the buyer be refunded?**

This function gives them the power to do exactly that.

---

### 🔍 Line by Line Breakdown

---

### 1. ✅ Only the Arbiter Can Call This

```solidity

require(msg.sender == arbiter, "Only arbiter can resolve");

```

This function is off-limits to the buyer and seller.

Why? Because this is about **unbiased resolution**.

Only the arbiter, who was defined at the start of the contract, can make this final call.

This keeps the process neutral and protects both sides.

---

### 2. 🔒 Only Allowed if We’re in a Dispute

```solidity

require(state == EscrowState.DISPUTED, "No dispute to resolve");

```

This function can only be used when the contract is in the `DISPUTED` state — no other time.

That means you can’t call this before a problem has been raised, or after the deal has already been completed or cancelled.

---

### 3. 🏁 Mark the Escrow as Complete

```solidity

state = EscrowState.COMPLETE;

```

No matter what decision the arbiter makes, the escrow is now **closed**.

This prevents any further actions (like cancelling or disputing again) and locks the final outcome into place.

---

### 4. 💸 Release Funds Based on Decision

```solidity

if (_releaseToSeller) {
    payable(seller).transfer(amount);
    emit DisputeResolved(arbiter, seller, amount);
} else {
    payable(buyer).transfer(amount);
    emit DisputeResolved(arbiter, buyer, amount);
}

```

The arbiter passes in a boolean value: `_releaseToSeller`.

- If it's `true`: The seller gets the ETH.
- If it's `false`: The buyer gets their ETH back.

After making the transfer, the function emits the `DisputeResolved` event — showing who won the dispute and how much they received.

> This makes the decision transparent and verifiable on-chain.

---

# ⏱️ `cancelAfterTimeout()` – Buyer Cancels if Seller Delays

```solidity

function cancelAfterTimeout() external {
    require(msg.sender == buyer, "Only buyer can trigger timeout cancellation");
    require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel in current state");
    require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");

    state = EscrowState.CANCELLED;
    payable(buyer).transfer(address(this).balance);
    emit EscrowCancelled(buyer);
    emit DeliveryTimeoutReached(buyer);
}

```

### 🧠 What This Function Does

This is your **emergency exit** as a buyer.

Let’s say you’ve locked your ETH in escrow. The seller was supposed to deliver something — but days go by, and nothing shows up. No delivery, no communication.

Rather than being stuck forever with your money locked in the contract, this function gives you a way to **back out** — but only if the agreed-upon deadline has passed.

Let’s break it down line by line.

---

### 👤 Step 1: Only the Buyer Can Cancel

```solidity

require(msg.sender == buyer, "Only buyer can trigger timeout cancellation");

```

Since the buyer is the one who deposited the funds, they’re the only one who can cancel the deal due to a delay.

This protects the buyer without giving the seller any way to trigger a premature cancellation.

---

### ⏳ Step 2: Only If We're Waiting for Delivery

```solidity

require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel in current state");

```

We can only use this function when funds have already been deposited and we're in the delivery phase.

If we’re still waiting for the buyer to deposit, or if the contract is already in a disputed, completed, or cancelled state — this function isn’t allowed.

---

### 🕒 Step 3: Check if the Timeout Has Passed

```solidity

require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");

```

Now we check whether the seller has missed their deadline.

- `depositTime` is when the buyer deposited the ETH.
- `deliveryTimeout` is the agreed duration the seller had to deliver.

If the current time (`block.timestamp`) is **equal to or greater than** that deadline, the buyer is allowed to cancel.

Otherwise, they’ll need to wait a little longer.

---

### ❌ Step 4: Cancel the Escrow

```solidity

state = EscrowState.CANCELLED;

```

We update the contract to mark the transaction as cancelled.

From this point forward, no one can confirm delivery, raise a dispute, or trigger any other actions.

---

### 💸 Step 5: Refund the Buyer

```solidity

payable(buyer).transfer(address(this).balance);

```

The funds are returned to the buyer in full.

We use `address(this).balance` instead of `amount` just to be extra safe — in case anything unexpected made it into the contract (though normally, only `amount` would be there).

---

### 📣 Step 6: Emit the Cancellation and Timeout Events

```solidity

emit EscrowCancelled(buyer);
emit DeliveryTimeoutReached(buyer);

```

These two events tell the frontend and any external listeners:

- The escrow was cancelled
- The reason was a **delivery timeout**

This helps provide transparency and explain what happened to users reviewing the transaction history.

---

# 🤝 `cancelMutual()` – Either Party Cancels Before Completion

```solidity

function cancelMutual() external {
    require(msg.sender == buyer || msg.sender == seller, "Not authorized");
    require(
        state == EscrowState.AWAITING_DELIVERY || state == EscrowState.AWAITING_PAYMENT,
        "Cannot cancel now"
    );

    EscrowState previousState = state;
    state = EscrowState.CANCELLED;

    if (previousState == EscrowState.AWAITING_DELIVERY) {
        payable(buyer).transfer(address(this).balance);
    }

    emit EscrowCancelled(msg.sender);
}

```

### 🧠 What This Function Does

Sometimes, both parties decide to call off the deal — no disputes, no timeouts, no drama.

Maybe the seller can’t fulfill the order anymore.

Maybe the buyer changed their mind.

Or maybe both sides agree it’s just not going to work out.

This function allows **either the buyer or seller** to cancel the escrow **before it's completed** — whether it’s just been created or funds have already been deposited.

Let’s break down exactly how that works.

---

### 🔐 Step 1: Only Buyer or Seller Can Cancel

```solidity

require(msg.sender == buyer || msg.sender == seller, "Not authorized");

```

This function is not open to the public.

Only the **buyer** or **seller** can trigger a mutual cancellation.

This ensures that the decision to cancel stays between the two people involved.

---

### 🕒 Step 2: Can Only Be Used at the Right Time

```solidity

require(
    state == EscrowState.AWAITING_DELIVERY || state == EscrowState.AWAITING_PAYMENT,
    "Cannot cancel now"
);

```

This function only works if the contract is still:

- Waiting for the buyer to deposit (`AWAITING_PAYMENT`)
- Or waiting for the seller to deliver (`AWAITING_DELIVERY`)

If the deal has already been completed, disputed, or cancelled — it’s too late.

And if a dispute has been raised, then cancellation must be handled by the arbiter.

---

### 🧭 Step 3: Store the Previous State

```solidity

EscrowState previousState = state;

```

We store the current state in a temporary variable so we can check later if the funds were already deposited.

Why does this matter?

Because if we’re cancelling **after** a deposit has been made, we need to **refund the buyer**.

---

### ❌ Step 4: Cancel the Escrow

```solidity

state = EscrowState.CANCELLED;

```

Once the decision is made to cancel, we mark the entire escrow as `CANCELLED`.

No further actions can be taken — this closes the transaction permanently.

---

### 💸 Step 5: Refund the Buyer (If Needed)

```solidity

if (previousState == EscrowState.AWAITING_DELIVERY) {
    payable(buyer).transfer(address(this).balance);
}

```

If the buyer had already deposited ETH, we refund it.

This ensures the seller doesn’t walk away with funds from an incomplete or cancelled transaction.

> 🔒 If the state was still AWAITING_PAYMENT, this condition is skipped — because no money was ever deposited.

---

### 📣 Step 6: Emit the Cancellation Event

```solidity

emit EscrowCancelled(msg.sender);

```

This emits a public event so that frontends and explorers can track that the deal was mutually cancelled — and see **who initiated it**.

That makes everything transparent and easy to follow.

---

# ⌛ `getTimeLeft()` – View How Much Time Remains

```solidity

function getTimeLeft() external view returns (uint256) {
    if (state != EscrowState.AWAITING_DELIVERY) return 0;
    if (block.timestamp >= depositTime + deliveryTimeout) return 0;
    return (depositTime + deliveryTimeout) - block.timestamp;
}

```

### 🧠 What This Function Does

This function doesn't change anything.

It doesn’t move money, update state, or trigger events.

Instead, it’s a **read-only helper** — designed to be used by the **frontend** to show how much time the seller has left to fulfill the delivery before the buyer can cancel using `cancelAfterTimeout()`.

It’s a small function, but incredibly useful for transparency and UX.

Let’s go through it line by line.

---

### ⛔ Step 1: Exit Early If We're Not Waiting for Delivery

```solidity

if (state != EscrowState.AWAITING_DELIVERY) return 0;

```

We only care about time left **while we're waiting for delivery**.

If we’re in any other state — waiting for payment, completed, disputed, cancelled — there’s **no countdown happening**. So we just return 0.

---

### 🕒 Step 2: If Timeout Already Passed, Return 0

```solidity

if (block.timestamp >= depositTime + deliveryTimeout) return 0;

```

If the current time has already passed the deadline, we again return 0.

At this point, the **buyer is eligible to cancel the escrow**, and there’s no time left to wait.

---

### ⏳ Step 3: Otherwise, Return Remaining Time

```solidity

return (depositTime + deliveryTimeout) - block.timestamp;

```

If the contract is waiting for delivery _and_ the deadline hasn’t passed yet, we calculate the **number of seconds left** until the buyer can cancel.

This is a simple subtraction:

- Deadline = `depositTime + deliveryTimeout`
- Now = `block.timestamp`

So the difference gives you the **remaining seconds**.

# 🧾 Walkthrough: Freelance Job Escrow

Let’s say Alice wants to hire Bob to build her a website. Since they don’t fully know each other, they decide to use a smart contract to hold the funds safely until the job is done. They also bring in a neutral third party, Charlie, to step in _if something goes wrong_.

The contract they’re using?

`EnhancedSimpleEscrow` — a trustless digital middleman written in Solidity.

---

## 🤝 The Setup

- **Buyer:** Alice (`0xAlice`)
- **Seller:** Bob (`0xBob`)
- **Arbiter:** Charlie (`0xCharlie`)
- **Delivery Timeout:** 3 days = `3 * 86400 = 259200` seconds

---

## 1️⃣ Contract Deployment – _(Day 0)_

Alice deploys the contract and defines the key players:

```solidity

EnhancedSimpleEscrow(
    seller = 0xBob,
    arbiter = 0xCharlie,
    deliveryTimeout = 259200  // 3 days
)

```

At this point:

- Alice becomes the **buyer** by default (since she’s the deployer).
- The state is set to `AWAITING_PAYMENT`.
- No ETH has been sent yet.

```

State: AWAITING_PAYMENT
Funds: 0 ETH

```

---

## 2️⃣ Alice Deposits Payment – _(Day 1)_

Alice decides to lock 2 ETH into the contract using the `deposit()` function:

```solidity

escrow.deposit{value: 2 ether}()

```

Let’s assume the block timestamp is:

`depositTime = 1_715_000_000`

Now:

- 2 ETH is locked in the contract.
- The contract state moves to `AWAITING_DELIVERY`.
- The countdown to timeout begins.

```

State: AWAITING_DELIVERY
Funds: 2 ETH
Deposit Time: 1_715_000_000

```

> 📣 Emits: PaymentDeposited

---

## 3️⃣ Bob Delivers Work – Now There Are 3 Possible Paths

---

### 🛣️ Path A: Smooth Delivery

Bob delivers the website, and Alice is happy.

She calls:

```solidity

escrow.confirmDelivery()

```

This does three things:

- Marks the escrow as `COMPLETE`
- Transfers 2 ETH to Bob
- Emits the event `DeliveryConfirmed`

```

State: COMPLETE
Funds: 0 ETH

```

> 🎉 Everything worked as expected. No one had to step in.

---

### 🛣️ Path B: Dispute Raised

Bob says he delivered, but Alice isn't satisfied with the work.

She calls:

```solidity

escrow.raiseDispute()

```

This:

- Moves the state to `DISPUTED`
- Emits the event `DisputeRaised`

Now the arbiter, Charlie, reviews both sides and decides the buyer is right.

He calls:

```solidity

escrow.resolveDispute(false)

```

Since `false` means “release to buyer,” the 2 ETH is refunded to Alice.

```

State: COMPLETE
Funds: 0 ETH

```

> 🎯 Dispute resolved fairly. Funds go to the rightful party.

---

### 🛣️ Path C: Seller Ghosts the Buyer

Bob disappears. Alice hears nothing.

She waits 3 full days. The timeout period passes:

```solidity

block.timestamp = 1_715_000_000 + 259200 = 1_715_259_200

```

Now she can trigger a cancellation:

```solidity

escrow.cancelAfterTimeout()

```

The contract:

- Confirms the timeout has passed
- Cancels the escrow
- Refunds the 2 ETH back to Alice
- Emits `EscrowCancelled` and `DeliveryTimeoutReached`

```

State: CANCELLED
Funds: 0 ETH

```

> ⏱️ No arbiter needed. The code enforced the deadline.

---

### 🛣️ Path D: Mutual Cancellation

Maybe Bob’s schedule got busy. Maybe Alice changed the scope of work.

They both agree to cancel the deal.

Either one of them calls:

```solidity

escrow.cancelMutual()

```

If ETH was already deposited:

- Funds go back to Alice
- State changes to `CANCELLED`
- Emits: `EscrowCancelled`

```

State: CANCELLED
Funds: 0 ETH

```

> ✌️ Clean and peaceful exit — with both parties in agreement.

## 🔚 Wrap-Up – Building Trust with Code

And that’s a wrap on today's project.

What we just built isn’t just another toy contract — it’s a real-world tool that solves a real-world problem:

> How do you trust someone you don’t know with your money?

With `EnhancedSimpleEscrow`, you don’t have to.

You learned how to build a **secure, transparent, and self-enforcing escrow system** that:

- Holds funds until both parties are satisfied
- Lets users raise disputes and get fair resolution
- Automatically refunds if someone fails to deliver
- Supports clean, mutual cancellations
- And keeps the entire process verifiable and trustless on-chain

All of this — managed not by a company or platform — but by a few lines of **smart contract logic**.

---

## What You Mastered Today

- ✅ How to define **roles and access control** (buyer, seller, arbiter)
- 🧠 How to use **enums** to model contract state transitions
- ⏳ How to enforce **timeouts** with `block.timestamp`
- ⚖️ How to resolve **disputes** fairly and securely
- 📣 How to use **events** for frontend visibility
- 🛠️ How to write functions that are **safe, clear, and enforce flow**

---

## Real Use Cases You Could Build From Here

This exact pattern can power:

- Freelance marketplaces
- NFT or digital goods trades
- Community bounties or grants
- Crowdfunding with conditional payouts
- Even DAO-controlled dispute resolution systems

Escrow is everywhere — and now, you know how to build it from scratch.
