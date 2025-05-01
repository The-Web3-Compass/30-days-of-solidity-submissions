Alright — we’ve made some serious progress in our Solidity journey so far.

We’ve learned how to:

- Assign **ownership**
- Use **modifiers** to guard functions
- Work with **mappings** to store user data
- Run a full-on **token sale**
- Build modular, plugin-based systems with **delegatecall**

But now, it’s time to **put all those skills into action** and solve a real-world problem — something every Web3 builder can relate to.

---

## 🎉 The Scenario: A Private Web3 Event

You’re organizing a **token-gated conference**, a **founders meetup**, or an **on-chain workshop**. Only selected guests should be allowed to enter.

Now here’s the challenge...

### The Traditional Approach:

- You’d store every attendee’s address on-chain.
- You’d check each one manually during check-in.
- You’d burn **gas** for every address update or typo.

❌ That’s clunky. That’s expensive. That’s not Web3.

---

## ✅ The Smarter Way: Off-Chain Signatures

Instead of uploading a big list of addresses...

What if:

- The **event organizer signs a message** for each approved guest
- The guest brings their **signed invite**
- The contract just **verifies the signature on check-in**
- No need to store any whitelists on-chain

And yes — it’s all done securely using Ethereum’s built-in **`ecrecover`** function.

---

# 🧩 Our Game Plan

Here’s what we’re going to build — and how we’ll break it down:

1. **Event Setup**

   The organizer defines the name, date, and max attendee count.

2. **Cryptographic Invites**

   Instead of storing addresses, the backend signs a message for each approved guest.

3. **Check-In Flow**

   Guests submit their signed message.

   The contract uses `ecrecover` to verify it was signed by the organizer.

4. **Security & Flexibility**

   No address list on-chain. No preloaded whitelist. No wasted gas.

   Only valid, signed attendees get in — and it’s all fully verifiable on-chain.

---

## 🛠 What You'll Learn

- How to **hash structured data** (`abi.encodePacked`)
- Why Ethereum uses **signed message prefixes**
- How `ecrecover()` lets you verify off-chain approvals on-chain
- How to implement a **lightweight, gas-efficient access system** that’s actually used in production today

---

## 🔍 Contract Breakdown: `EventEntry.sol`

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EventEntry {
    string public eventName;
    address public organizer;
    uint256 public eventDate;
    uint256 public maxAttendees;
    uint256 public attendeeCount;
    bool public isEventActive;

    mapping(address => bool) public hasAttended;

    event EventCreated(string name, uint256 date, uint256 maxAttendees);
    event AttendeeCheckedIn(address attendee, uint256 timestamp);
    event EventStatusChanged(bool isActive);

    constructor(string memory _eventName, uint256 _eventDate_unix, uint256 _maxAttendees) {
        eventName = _eventName;
        eventDate = _eventDate_unix;
        maxAttendees = _maxAttendees;
        organizer = msg.sender;
        isEventActive = true;

        emit EventCreated(_eventName, _eventDate_unix, _maxAttendees);
    }

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only the event organizer can call this function");
        _;
    }

    function setEventStatus(bool _isActive) external onlyOrganizer {
        isEventActive = _isActive;
        emit EventStatusChanged(_isActive);
    }

    function getMessageHash(address _attendee) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), eventName, _attendee));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_attendee);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == organizer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function checkIn(bytes memory _signature) external {
        require(isEventActive, "Event is not active");
        require(block.timestamp <= eventDate + 1 days, "Event has ended");
        require(!hasAttended[msg.sender], "Attendee has already checked in");
        require(attendeeCount < maxAttendees, "Maximum attendees reached");
        require(verifySignature(msg.sender, _signature), "Invalid signature");

        hasAttended[msg.sender] = true;
        attendeeCount++;

        emit AttendeeCheckedIn(msg.sender, block.timestamp);
    }
}

```

This contract is designed for Web3 events like conferences, workshops, or private meetups. But instead of storing a long list of whitelisted addresses on-chain (which costs gas and isn't scalable), we do something smarter.

Here's the trick:

> The event organizer signs a message off-chain for each approved attendee.
>
> The attendee then brings that signed message on-chain to **prove** they were invited.

No need to store anything up front. The smart contract verifies the signature using `ecrecover`.

This is efficient, secure, and mirrors how IRL tickets or QR codes work — but on-chain.

---

### 📄 Contract Declaration

```solidity

pragma solidity ^0.8.17;

contract EventEntry {

```

We’re using Solidity version 0.8.17 and creating a contract called `EventEntry`. Simple start.

---

### 🧾 Event Details & State Variables

Before we dive into the core logic of our smart contract, let’s step back and ask a simple question:

> What does a Web3 event actually need to manage on-chain?

We’re not just writing a generic attendance tracker — we’re building a **signature-based, gas-optimized, private access system** for an event. That means we need to track things like:

- What the event is
- Who’s in charge
- When it’s happening
- How many people can attend
- Who has already checked in
- Whether the doors are still open

Let’s look at how all that gets stored inside the contract.

```solidity

string public eventName;
address public organizer;
uint256 public eventDate;
uint256 public maxAttendees;
uint256 public attendeeCount;
bool public isEventActive;

```

These six variables define **everything about your event** — from who’s in charge to how many people can enter. Let’s go through each one, line by line:

---

```solidity
string public eventName;
```

This is the **human-readable name** of your event — like `"EthConf 2025"` or `"Token-Gated Summit"`.

- Since it’s marked `public`, Solidity automatically creates a getter function.
- Anyone can call `eventName()` to fetch this value — perfect for frontends or explorers to show the event’s title.

---

```solidity
address public organizer;
```

This is the **Ethereum address of the event organizer** — the person or entity that deployed the contract.

- Only this address can **sign attendee approvals** (off-chain).
- Only this address can **change the event status** (`setEventStatus()`).
- This makes the organizer the gatekeeper for the whole system.

---

```solidity
uint256 public eventDate;
```

This holds the **event's scheduled date**, expressed as a **Unix timestamp**.

- Example: `1714569600` → April 30, 2024 at 00:00:00 UTC
- It’s used in the `checkIn()` function to make sure people can’t check in too late.
- The contract allows check-ins until `eventDate + 1 day` to allow for timezone and delay flexibility.

So in practice, the event **closes** one day after this timestamp.

---

```solidity
 uint256 public maxAttendees;
```

This sets a **hard cap** on how many people can check in.

- If set to `100`, only 100 unique addresses can check in successfully.
- Useful for managing limited seating, physical constraints, or access control at private events.

---

```solidity
uint256 public attendeeCount;
```

This keeps a **running total** of how many people have already checked in.

- Starts at `0`
- Increments by 1 each time a new user successfully checks in
- Used to enforce the `maxAttendees` rule

---

```solidity
bool public isEventActive;
```

This variable determines whether the event is **currently accepting check-ins**.

- Set to `true` when the contract is deployed
- Can be toggled on/off by the organizer using `setEventStatus(bool)`
- Prevents check-ins if the event is inactive

---

### Attendance Tracking

```solidity

mapping(address => bool) public hasAttended;

```

We use this mapping to **track who has already checked in** — so no one can check in twice.

---

### 📢 Events

```solidity

event EventCreated(string name, uint256 date, uint256 maxAttendees);
event AttendeeCheckedIn(address attendee, uint256 timestamp);
event EventStatusChanged(bool isActive);

```

We emit these events for transparency and frontend integration:

- `EventCreated`: Emitted once during deployment.
- `AttendeeCheckedIn`: Fired every time someone successfully checks in.
- `EventStatusChanged`: Lets the organizer pause/resume the event.

---

### 🏗️ Constructor: Setup at Deployment

```solidity

constructor(string memory _eventName, uint256 _eventDate_unix, uint256 _maxAttendees) {
    eventName = _eventName;
    eventDate = _eventDate_unix;
    maxAttendees = _maxAttendees;
    organizer = msg.sender;
    isEventActive = true;

    emit EventCreated(_eventName, _eventDate_unix, _maxAttendees);
}

```

The `constructor` is like the setup wizard that runs once — and only once — when the contract is deployed. Let’s walk through what each line is doing and why it matters:

---

```solidity
eventName = _eventName;
```

This stores the human-readable name of your event (e.g., `"Web3Conf 2025"`). It’s passed in as a constructor argument and saved on-chain so anyone can query it later using the `eventName()` function.

---

```solidity
eventDate = _eventDate_unix;
```

This sets the official event date — but it’s not a formatted string like `"April 21, 2025"`. It’s a **Unix timestamp** (like `1745251200`), which makes it easier to do time comparisons in Solidity.

Later, we’ll use this to check whether the event is still ongoing or has already ended.

---

```solidity
maxAttendees = _maxAttendees;
```

This sets a cap on how many people can attend. For example, if the max is 150, then the 151st person will be rejected during check-in.

Having this built-in limit helps prevent overcrowding, spamming, or abuse.

---

```solidity
organizer = msg.sender;
```

This sets the person who deployed the contract as the **event organizer**.

- `msg.sender` in the constructor refers to the address that deployed the contract.
- This address gets special powers — like activating/deactivating the event.

It’s also the **only** address that should be allowed to sign invite signatures, which we’ll validate later.

---

```solidity
isEventActive = true;
```

By default, the event starts as active — meaning check-ins are allowed unless the organizer disables it manually.

We’ll later create a function called `setEventStatus()` to let the organizer toggle this flag.

---

```solidity
emit EventCreated(...)
```

This line broadcasts an event to the blockchain that the event was created.

Why emit an event?

- It helps off-chain apps (like frontends or explorers) know that a new event has been registered.
- It logs useful metadata like the name, date, and max capacity.

---

### 🔐 Access Control

```solidity

modifier onlyOrganizer() {
    require(msg.sender == organizer, "Only the event organizer can call this function");
    _;
}

```

A handy **modifier** to protect certain functions. Only the organizer can call them.

---

### 🔁 Toggle Event Status

```solidity

function setEventStatus(bool _isActive) external onlyOrganizer {
    isEventActive = _isActive;
    emit EventStatusChanged(_isActive);
}

```

Use this to **pause or resume** check-ins. You might want to freeze check-in after a certain point.

---

### 🔏 Message Hashing — Key to Signatures

```solidity

function getMessageHash(address _attendee) public view returns (bytes32) {
    return keccak256(abi.encodePacked(address(this), eventName, _attendee));
}

```

This function gives the **organizer** the power to control whether the event is currently accepting check-ins or not.

---

### 🧱 What It Does:

- **`onlyOrganizer` modifier:**
  Ensures that only the person who deployed the contract (the `organizer`) can change this setting. This prevents random users from pausing or resuming the event.
- **`isEventActive = _isActive;`**
  Updates the event’s active state based on the argument passed:
  - If `_isActive` is `true`, the event is open.
  - If `_isActive` is `false`, check-ins are temporarily paused.
- **`emit EventStatusChanged(_isActive);`**
  Emits an on-chain event every time the status changes — useful for frontend dashboards or blockchain explorers to reflect the change immediately.

---

### ✍️ Ethereum Signed Message Hash

```solidity

function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
}

```

This function is a **crucial part** of Ethereum’s signature verification system — and here’s why it exists.

---

### 🧠 Why This Function Exists

When a user signs data off-chain (like a hash of a message), they’re technically signing **any random 32 bytes**. That could include the hash of a transaction, the hash of a contract, or some completely unrelated data.

This introduces a risk:

> What if someone tricks a user into signing something off-chain, and then reuses that signature on-chain to do something malicious?

To avoid that, Ethereum introduced a **protective prefix**.

---

### 🔐 What the Function Does

This line:

```solidity

keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));

```

takes your original message hash and **wraps it with a prefix**, like so:

```

"\x19Ethereum Signed Message:\n32" + original_hash

```

Then it hashes the whole thing again using `keccak256`.

This is known as the **Ethereum Signed Message Hash**, and it’s the **exact format** that wallets like MetaMask use when you call `eth_sign`.

---

### 🔄 Why Is This Important?

Because when we **recover the signer’s address** later using `ecrecover()`, we’ll be recovering it from this **prefix-wrapped hash**, not the raw hash.

If you don’t wrap it correctly, the verification step will fail — even if the user signed it correctly!

---

###

---

### 🕵️‍♂️ Signature Verification

```solidity

function verifySignature(address _attendee, bytes memory _signature) public view returns (bool) {
    bytes32 messageHash = getMessageHash(_attendee);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
    return recoverSigner(ethSignedMessageHash, _signature) == organizer;
}

```

This function is the core of our **invite validation system**. It answers a simple but powerful question:

> “Was this signature really created by the organizer — and was it meant for this attendee?”

Let’s break it down, line by line.

---

### ✅ Step 1: Generate the Base Message Hash

```solidity

bytes32 messageHash = getMessageHash(_attendee);

```

This recreates the exact hash that the **organizer signed** off-chain for a specific attendee.

That hash is usually something like:

```

keccak256(contract address + event name + attendee address)

```

This ensures that:

- The signature is **tied to this specific contract**
- It’s only valid for **this event**
- It belongs to **this exact user**

If anything is different — different attendee, different event — the hash changes.

---

### ✅ Step 2: Convert to Ethereum-Signed Format

```solidity

bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

```

As we explained earlier, this wraps the message hash with Ethereum’s standard prefix:

```

"\x19Ethereum Signed Message:\n32" + messageHash

```

Why?

Because wallets like MetaMask automatically add that prefix when signing — so we need to include it too when verifying, otherwise the check will fail.

---

### ✅ Step 3: Recover the Signer

```solidity

return recoverSigner(ethSignedMessageHash, _signature) == organizer;

```

Here, we:

- Use `ecrecover()` (via the helper function `recoverSigner`) to extract the address of **who signed the message**.
- Compare that address with `organizer` — the address that deployed this contract.

If they match: ✅ the signature is valid

If not: ❌ someone forged it or it was signed by someone else

---

## 🔐 `recoverSigner` – The Cryptographic Detective

Here’s the actual function from the contract:

```solidity

function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    public
    pure
    returns (address)
{
    require(_signature.length == 65, "Invalid signature length");

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
        r := mload(add(_signature, 32))
        s := mload(add(_signature, 64))
        v := byte(0, mload(add(_signature, 96)))
    }

    if (v < 27) {
        v += 27;
    }

    require(v == 27 || v == 28, "Invalid signature 'v' value");

    return ecrecover(_ethSignedMessageHash, v, r, s);
}

```

---

This function is the **final detective step** in our signature-based entry system. It looks at a signature and figures out **which Ethereum address signed it**.

Let’s say someone gives us a signature and claims:

> "This was signed by the event organizer. That means I’m allowed to enter the event."

Cool. But we can’t just trust them blindly. We need to **verify** if:

1. That signature is valid.
2. It really came from the **organizer’s wallet**.

This function helps us do exactly that.

---

### 📏 Step 1: Check the Signature Length

```solidity

require(_signature.length == 65, "Invalid signature length");

```

All Ethereum signatures are **65 bytes long** — no more, no less.

If it’s shorter or longer, it’s probably corrupted, incomplete, or fake.

So we immediately stop if the length is wrong.

---

### 📦 Step 2: Break the Signature Into 3 Parts

Ethereum signatures aren’t just one big chunk — they’re made of 3 pieces called:

- `r` (32 bytes)
- `s` (32 bytes)
- `v` (1 byte)

These three values work together to **mathematically prove who signed the message**.

Now here's where things get a little technical…

---

### 🧙 Step 3: Use Assembly to Extract Those Values

```solidity

assembly {
    r := mload(add(_signature, 32))
    s := mload(add(_signature, 64))
    v := byte(0, mload(add(_signature, 96)))
}

```

Assembly is a low-level way to access data directly from memory.

Think of it like digging into a box and pulling out exactly what we need.

We’re saying:

- "Hey Ethereum, give me the first 32 bytes starting at position 32. That’s `r`."
- "Now give me the next 32 bytes starting at 64. That’s `s`."
- "And finally give me the 1 byte at position 96. That’s `v`."

We now have all the pieces of the signature puzzle.

---

### 🧪 Step 4: Fix the `v` Value if Needed

```solidity

if (v < 27) {
    v += 27;
}

```

Sometimes, different wallets or systems will give you a `v` value that’s 0 or 1.

But Ethereum expects it to be 27 or 28.

So we just adjust it if needed.

---

### 🚨 Step 5: Validate That `v` Is Now Correct

```solidity

require(v == 27 || v == 28, "Invalid signature 'v' value");

```

After fixing, we make sure that `v` is either 27 or 28 — nothing else is acceptable.

If it’s anything else, we throw an error because we can’t trust the signature.

---

### 🔍 Step 6: Recover the Signer’s Address

```solidity

return ecrecover(_ethSignedMessageHash, v, r, s);

```

Here’s the final moment.

We call `ecrecover` — a built-in Ethereum function that takes:

- The signed message hash
- The signature values (`v`, `r`, `s`)

And it returns the **address of the signer**.

Boom! We now know who signed this message.

---

## 🎟️ `checkIn` – The Front Gate of the Web3 Event

This is the main function that attendees will call when they arrive at your event — **whether it’s a token-gated meetup, a workshop, or a private launch party**.

Let’s revisit the function first:

```solidity

function checkIn(bytes memory _signature) external {
    require(isEventActive, "Event is not active");
    require(block.timestamp <= eventDate + 1 days, "Event has ended");
    require(!hasAttended[msg.sender], "Attendee has already checked in");
    require(attendeeCount < maxAttendees, "Maximum attendees reached");
    require(verifySignature(msg.sender, _signature), "Invalid signature");

    hasAttended[msg.sender] = true;
    attendeeCount++;

    emit AttendeeCheckedIn(msg.sender, block.timestamp);
}

```

---

### 🧩 What is this function doing?

This function is **your digital gatekeeper**.

Every time someone wants to check in, they must prove:

- They were invited (by providing a valid signature)
- They’re checking in within the allowed window
- The event is still open
- They haven’t already checked in
- There’s still room!

If they pass all those checks, they’re allowed through the gate.

Now let’s break this function line by line:

---

```solidity
require(isEventActive, "Event is not active");
```

Before we check anything else — is the event even live?

The organizer might have paused or cancelled the event. If so, **nobody is allowed to check in**.

This flag (`isEventActive`) is controlled by the organizer using the `setEventStatus()` function.

---

```solidity
require(block.timestamp <= eventDate + 1 days, "Event has ended");
```

This check says: **“You can only check in until 24 hours after the event date.”**

Why?

Because events don’t last forever. You don’t want someone trying to check in 5 days later.

By adding one extra day, we give a slight grace period while still keeping things realistic.

---

```solidity
require(!hasAttended[msg.sender], "Attendee has already checked in");
```

We don’t allow duplicate check-ins.

This line makes sure **each address can only check in once**. If they’ve already been marked as attended, they’re blocked from checking in again.

This is tracked using the `hasAttended` mapping.

---

```solidity
require(attendeeCount < maxAttendees, "Maximum attendees reached");
```

This is your **event cap**.

If your max is 100 attendees, and 100 people already checked in, the door is closed — no matter who’s trying to enter.

Even if they have a valid signature, they can’t get in once the cap is hit.

---

```solidity
require(verifySignature(msg.sender, _signature), "Invalid signature");
```

Here’s the real magic.

This line verifies that:

- The attendee (`msg.sender`) was **actually invited**
- Their signature was **signed by the event organizer**
- It was signed specifically **for this event**

This uses all the cryptographic logic we talked about earlier (message hashing, Ethereum prefixes, `ecrecover`) — wrapped neatly in the `verifySignature()` helper.

If the signature is fake or invalid, access is denied.

---

### ✅ Passed All Checks? Great!

If the attendee passes all the requirements, we record their check-in:

---

```solidity
hasAttended[msg.sender] = true;
```

We mark the caller as someone who has now checked in.

This prevents duplicate check-ins.

---

```solidity
attendeeCount++;
```

We increment the overall attendee count.

This helps us enforce the `maxAttendees` limit for the next person trying to enter.

---

```solidity
emit AttendeeCheckedIn(msg.sender, block.timestamp);
```

We fire an event to log that this person has checked in — and when.

This is useful for:

- Frontend UIs
- Block explorers
- Off-chain data indexing (like The Graph)

# 🧪 How to Run Your Signature-Based Event Entry System in Remix

Alright, time to bring our smart contract to life.

You’re the organizer. You’re about to host the **Web3 Summit**. Let’s go through it from start to finish — including signing invites and checking people in!

---

## 🔨 Step 1: Deploy the Contract

1. Head over to Remix.
2. Paste your `EventEntry` contract into a new file — name it `EventEntry.sol`.
3. Compile it using the **Solidity Compiler** tab.
4. Go to the **Deploy & Run Transactions** tab.

Now it’s time to fill in the constructor:

- `eventName`: `"Web3 Summit"`
- `eventDate`: Use a **future Unix timestamp**
  → You can use something like `Math.floor(Date.now() / 1000) + 86400` (which is now + 1 day)
  → Or just paste a hardcoded future timestamp like `1714000000`
- `maxAttendees`: `100`

Hit **Deploy**.

Congrats! You’ve now launched your smart event.

---

## 🔑 Step 2: Generate the Message Hash

To invite a guest, we need to **generate a unique hash** tied to their wallet.

In your deployed contract instance:

Call:

```solidity
getMessageHash("0xAttendeeAddressHere")

```

🧠 Replace `"0xAttendeeAddressHere"` with the guest's wallet address.

Copy the returned hash — we’ll use it in the next step.

---

## ✍️ Step 3: Sign the Message in Remix

Time to act as the **event organizer** and sign the guest’s hash.

### Create a JavaScript file:

1. In the **File Explorer**, right-click and select **New File**
2. Name it `sign.js`

Paste this script:

```jsx
(async () => {
  const messageHash = "<paste-your-hash-here>";
  const accounts = await web3.eth.getAccounts();
  const organizer = accounts[0]; // first account in Remix
  const signature = await web3.eth.sign(messageHash, organizer);
  console.log("Signature:", signature);
})();
```

Replace `"<paste-your-hash-here>"` with the hash you just copied.

### Now run it:

Right-click on `sign.js` and select **Run**.

✅ Remix automatically includes **web3.js**, so you don’t need to install anything.

You’ll see the signature printed in the Remix terminal.

🧠 What’s happening here?

We’re using the **private key** of the deployer (i.e., the organizer) to **sign the message hash** off-chain. This simulates what your backend server would do IRL.

---

## 🪪 Step 4: Check In as an Attendee

Now let’s switch roles — you’re an attendee arriving at the event, so switch to the attendee address

```solidity

checkIn("<paste-signature-here>")

```

📌 Paste the exact signature you got from the previous step.

If all goes well:

- You’ll be marked as checked in
- The event’s attendee count will increase
- The contract will emit an `AttendeeCheckedIn` event 🎉

## Wrap up

And just like that, we’ve built our very own Web3 guest list — without storing a single address on-chain. Instead of cluttering up storage or paying gas to update a whitelist, we used cryptographic signatures to let attendees prove they were invited. The event organizer acts like a digital bouncer, signing off approvals behind the scenes, while the smart contract checks those signatures at the door. It’s clean, efficient, and way more flexible — the kind of system real events could actually use. Whether you’re running a token-gated party or a developer meetup, this pattern gives you all the security without the on-chain baggage.
