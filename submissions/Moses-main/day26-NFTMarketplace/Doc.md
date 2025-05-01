# NFT Marketplace

###

Hey hey, welcome back to **30 Days of Solidity** — where every day, you level up not just by reading about how smart contracts work…

But by actually building things that _feel_ like real-world apps.

And today?

We’re shifting gears from **minting NFTs** to **monetizing them**.

This isn’t just a learning exercise.

This is your first step into building something that looks and feels like a real product.

Something that could run on mainnet. Something your favorite NFT artist could use to list their work.

Today…

you’re building your own **NFT Marketplace**.

---

### 🛍️ Let’s Talk About Marketplaces

Think about your favorite online marketplace — maybe it’s OpenSea, maybe it's Etsy, maybe it’s your neighborhood flea market.

There’s always the same 3 roles:

- Someone **selling** something valuable
- Someone **buying** it
- And a platform in the middle that handles the transaction, takes a cut, and moves the goods

Now take that idea — and put it entirely on-chain.

No middleman. No backend. No one standing in the way.

Just a smart contract that:

- Lists NFTs
- Handles ETH payments
- Pays out the seller, the platform, and even the original creator — **automatically**

---

### 🧠 Why This Project Is A Big Deal

NFT Marketplaces are where it all comes together:

- ERC721 logic ✅
- Secure ETH transfers ✅
- Royalties for creators ✅
- Fee distribution ✅
- Reentrancy protection ✅
- Ownership + approval flow ✅

It’s the kind of contract that shows you how real-world Web3 apps work under the hood.

And when you build this… you’re not just copying OpenSea.

You’re understanding it — and creating your own stripped-down, no-bloat version of it.

A version **you control**.

---

### 🧾 What You’ll Learn Today

- How to **list** an NFT with a custom price and optional royalty
- How to **buy** an NFT using ETH (with automatic splits to seller, creator, and marketplace)
- How to **unlist** an NFT if the seller changes their mind
- How to **protect** everything with `ReentrancyGuard`
- And how to **track and update fees** with full control as the contract owner

---

### 💡 What Makes This Special?

This marketplace doesn’t just let people trade NFTs.

It:

- Respects creator royalties
- Automatically enforces ownership
- Makes sure everyone gets paid correctly (seller, creator, and you!)
- Requires **no backend** and **no trust** — everything is enforced by code

You're not building a UI that _pretends_ to do things.

You're building the backend logic that actually _does_ them — live, on-chain.

---

## 🚀 By the End of This

You’ll have a self-contained NFT marketplace contract that can:

- List any ERC-721
- Sell it for ETH
- Distribute fees
- Transfer the NFT securely
- Log all activity with events for frontends to pick up

It’s like your own little OpenSea — but on your terms.

## 🧾 Overview: How This NFT Marketplace Contract Works

So what are we building, really?

This contract is a **fully on-chain NFT marketplace**, written in pure Solidity. It lets people:

- **List their NFTs for sale**, setting a price and even a custom royalty
- **Buy NFTs** by sending ETH directly to the contract
- **Automatically split the sale** between the seller, the creator (for royalties), and the platform (for marketplace fees)
- **Cancel listings** anytime
- And **update fee settings** as the marketplace owner

All of this happens **securely**, with built-in protections like `ReentrancyGuard` to prevent attacks.

There’s no frontend here, no JavaScript, no backend database — just a smart contract that:

- Tracks every listing
- Verifies every NFT and seller
- Moves ETH and NFTs correctly
- Emits events so UIs can follow along

This is the same foundation that platforms like **OpenSea** and **LooksRare** are built on — but cleaner, simpler, and beginner-friendly.

## 🧾 Full NFT Marketplace Contract

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    address public owner;
    uint256 public marketplaceFeePercent; // in basis points (100 = 1%)
    address public feeRecipient;

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address royaltyReceiver;
        uint256 royaltyPercent; // in basis points
        bool isListed;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    );

    event Purchase(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address royaltyReceiver,
        uint256 royaltyAmount,
        uint256 marketplaceFeeAmount
    );

    event Unlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event FeeUpdated(
        uint256 newMarketplaceFee,
        address newFeeRecipient
    );

    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        require(_marketplaceFeePercent <= 1000, "Marketplace fee too high (max 10%)");
        require(_feeRecipient != address(0), "Fee recipient cannot be zero");

        owner = msg.sender;
        marketplaceFeePercent = _marketplaceFeePercent;
        feeRecipient = _feeRecipient;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Marketplace fee too high");
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _newRecipient;
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);
    }

    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    ) external {
        require(price > 0, "Price must be above zero");
        require(royaltyPercent <= 1000, "Max 10% royalty allowed");
        require(!listings[nftAddress][tokenId].isListed, "Already listed");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            price: price,
            royaltyReceiver: royaltyReceiver,
            royaltyPercent: royaltyPercent,
            isListed: true
        });

        emit Listed(msg.sender, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent);
    }

    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(msg.value == item.price, "Incorrect ETH sent");
        require(
            item.royaltyPercent + marketplaceFeePercent <= 10000,
            "Combined fees exceed 100%"
        );

        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
        uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

        // Marketplace fee
        if (feeAmount > 0) {
            payable(feeRecipient).transfer(feeAmount);
        }

        // Creator royalty
        if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
            payable(item.royaltyReceiver).transfer(royaltyAmount);
        }

        // Seller payout
        payable(item.seller).transfer(sellerAmount);

        // Transfer NFT to buyer
        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        // Remove listing
        delete listings[nftAddress][tokenId];

        emit Purchase(
            msg.sender,
            nftAddress,
            tokenId,
            msg.value,
            item.seller,
            item.royaltyReceiver,
            royaltyAmount,
            feeAmount
        );
    }

    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(item.seller == msg.sender, "Not the seller");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }

    receive() external payable {
        revert("Direct ETH not accepted");
    }

    fallback() external payable {
        revert("Unknown function");
    }
}

```

---

## 📦 1. Imports – Bringing in Trusted Building Blocks

```solidity

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

```

These two lines are **pulling in powerful, battle-tested components** from the OpenZeppelin Contracts library. Let's look at what they do:

---

### ✅ `IERC721`

```solidity

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

```

This brings in the **interface** for any ERC-721 NFT — which is the standard used for non-fungible tokens (NFTs).

Think of `IERC721` like a contract blueprint that defines:

- Who owns a token (`ownerOf`)
- How to safely send a token (`safeTransferFrom`)
- How to approve someone to transfer your NFTs (`approve`, `isApprovedForAll`, etc.)

By importing this, we can **interact with any NFT contract** — not just NFTs we created, but _any ERC-721 compliant contract_, like a Bored Ape or a custom in-game item.

> 🧠 We don’t need the full NFT contract here — we’re not creating NFTs.
>
> We’re just **working with existing NFTs**, so we only need the interface to call their functions.

---

### 🛡️ `ReentrancyGuard`

```solidity

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

```

This is a **security tool** that helps protect our contract from a common type of hack called a **reentrancy attack**.

What’s that?

> Imagine someone starts buying an NFT, and before that transaction finishes, they sneak in another one (or a loop of transactions), messing up balances and draining funds.

By using `ReentrancyGuard`, we can **lock down our sensitive functions** like `buyNFT()` so no one can re-enter and exploit the logic halfway through.

We’ll apply this guard using the `nonReentrant` modifier.

---

## 🏗️ 2. Contract Declaration – Starting the Marketplace

```solidity

contract NFTMarketplace is ReentrancyGuard {

```

This line kicks off the actual smart contract — and it’s doing **two big things**:

1. **Naming our contract**
   - It’s called `NFTMarketplace` — this is how other contracts, tools, and frontends will reference it.
2. **Inheriting from ReentrancyGuard**
   - By doing this, our contract _automatically gets protection_ from reentrancy attacks on any function where we use the `nonReentrant` modifier.
   - It’s like giving our sensitive functions a personal bodyguard.

---

### 🔑 Why This Setup Matters

With just these two imports and the declaration, we’ve set the stage for:

- Working with any ERC-721 NFT contract
- Keeping our marketplace safe from critical vulnerabilities

Now we’re ready to dive into the **state variables** — the data our contract stores to keep track of listings, fees, and ownership.

---

# 3. state vaiables

These variables live at the top of the contract:

```solidity

address public owner;
uint256 public marketplaceFeePercent; // in basis points (100 = 1%)
address public feeRecipient;

```

---

## 🧠 What These Variables Do

These three values give our marketplace its **basic admin controls and revenue logic**. They define:

- Who’s in charge
- How much fee the marketplace takes
- Where those fees go

Let’s unpack each one:

---

### 👑 `owner`

```solidity

address public owner;

```

- This stores the **address that deployed the contract**.
- The owner is considered the **admin** — the only one allowed to update fees or change the fee recipient.

> 💡 Why track ownership manually?
>
> Because this isn’t using OpenZeppelin’s `Ownable` contract — we’re keeping it lean and writing our own basic access control.

You’ll see a modifier later in the code called `onlyOwner` that uses this value.

---

### 💸 `marketplaceFeePercent`

```solidity

uint256 public marketplaceFeePercent; // in basis points (100 = 1%)

```

This sets the **fee percentage** the marketplace will take from each sale — but in **basis points**.

> 🧾 What’s a basis point?
>
> 1 basis point = 0.01%.
>
> So 100 basis points = 1%.
>
> And 1000 basis points = 10%.

Using basis points gives us **fine-grained control** over fees and avoids Solidity’s lack of decimals.

For example:

- A fee of `250` means 2.5% of every sale goes to the marketplace.

This variable can be updated later by the owner.

---

### 🏦 `feeRecipient`

```solidity

address public feeRecipient;

```

This is the **wallet that receives the marketplace’s cut** from every NFT sale.

It could be:

- The marketplace founder
- A DAO treasury
- A multisig wallet
- Or even a smart contract that auto-distributes funds

---

# 4. Struct and Mapping

now we’re getting into the **core data model** of the marketplace: the **`Listing` struct** and the **mapping** that stores all the listed NFTs.

This is where your marketplace keeps track of what’s up for sale, who owns it, how much it costs, and who gets paid what.

---

## 🧱 The `Listing` Struct

```solidity

struct Listing {
    address seller;
    address nftAddress;
    uint256 tokenId;
    uint256 price;
    address royaltyReceiver;
    uint256 royaltyPercent; // in basis points
    bool isListed;
}

```

This struct is like a **mini database entry** for a single NFT that’s been listed on the marketplace.

Let’s break down each field:

---

### 🧍 `seller`

```solidity

address seller;

```

The person who listed the NFT.

They’ll be the one who receives most of the payment (after marketplace fees and royalties).

---

### 🖼️ `nftAddress`

```solidity

address nftAddress;

```

This is the **contract address** of the NFT.

Your marketplace supports _any_ ERC-721 token — not just one collection — so we need to know **which NFT contract** this token belongs to.

---

### 🏷️ `tokenId`

```solidity

uint256 tokenId;

```

The **ID of the NFT** being listed.

Together with `nftAddress`, this points to a specific NFT on the blockchain.

---

### 💰 `price`

```solidity

uint256 price;

```

The amount (in **ETH**) the seller wants for the NFT.

When someone buys it, they’ll need to send exactly this amount of ETH.

---

### 🎨 `royaltyReceiver`

```solidity

address royaltyReceiver;

```

Optional: The address that should receive **creator royalties** from this sale.

This allows creators to continue earning from secondary sales, even if they’re not the seller anymore.

---

### 📈 `royaltyPercent`

```solidity

uint256 royaltyPercent; // in basis points

```

How much royalty the `royaltyReceiver` should get — in basis points (1% = 100).

Example:

- If `price = 1 ETH` and `royaltyPercent = 500`, the creator gets `0.05 ETH`.

> 🎯 You can customize this per listing — no fixed royalty baked into the NFT contract required.

---

### 📦 `isListed`

```solidity

bool isListed;

```

A flag that tells us whether the NFT is **currently listed**.

We use this to:

- Prevent duplicate listings
- Check whether something is still for sale
- Control what shows up in the marketplace frontend

---

## 📚 The Mapping: Storing All Listings

```solidity

mapping(address => mapping(uint256 => Listing)) public listings;

```

This is how we **store and organize** all the listings in the contract.

It’s a **nested mapping**, meaning:

- The first key is the **NFT contract address**
- The second key is the **token ID**

So if you want to access the listing for a particular NFT, you'd use:

```solidity

listings[nftAddress][tokenId]

```

> 💡 Why nested?
>
> Because this allows multiple different NFT collections to be supported — all in one contract. It’s clean, scalable, and works well with any ERC-721.

## 🔔 5 Key Events in the NFT Marketplace

Events might seem like background noise at first… but they’re actually **the primary way** smart contracts talk to the outside world.

When something happens on-chain — like listing an NFT or making a sale — we emit an **event** so that:

- Frontend apps (like your marketplace UI) can pick it up and display it
- Indexers (like The Graph) can track and categorize it
- Developers and users can view it on block explorers like Etherscan

They don’t affect the logic inside the contract — but they’re essential for **transparency and usability**.

Here are the four events defined in the contract:

```solidity

event Listed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address royaltyReceiver,
    uint256 royaltyPercent
);

event Purchase(
    address indexed buyer,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address seller,
    address royaltyReceiver,
    uint256 royaltyAmount,
    uint256 marketplaceFeeAmount
);

event Unlisted(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId
);

event FeeUpdated(
    uint256 newMarketplaceFee,
    address newFeeRecipient
);

```

---

Now, let’s break them down one by one:

---

### ✅ 1. `Listed`

```solidity

event Listed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address royaltyReceiver,
    uint256 royaltyPercent
);

```

This event is emitted when an NFT is **listed** for sale.

It tells the world:

- **Who** listed it (`seller`)
- **Which NFT** is being sold (`nftAddress`, `tokenId`)
- **For how much** (`price`)
- **Who gets royalties**, and **how much** (`royaltyReceiver`, `royaltyPercent`)

The `indexed` fields make it easy to filter listings by seller or NFT in UIs and explorer tools.

---

### 🛍️ 2. `Purchase`

```solidity

event Purchase(
    address indexed buyer,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address seller,
    address royaltyReceiver,
    uint256 royaltyAmount,
    uint256 marketplaceFeeAmount
);

```

This event fires when someone **buys an NFT**.

It includes:

- The **buyer**’s address
- The **NFT** that was sold (by `nftAddress` and `tokenId`)
- The **total price** paid
- The **seller** who receives the ETH (minus fees)
- The **royalty receiver** (if any) and how much they got
- The **marketplace fee amount**

This is the most detailed event — it tracks **every part of the transaction**. Useful for:

- Frontends displaying purchase receipts
- Analytics dashboards showing marketplace revenue
- Creator royalty reports

---

### 🚫 3. `Unlisted`

```solidity

event Unlisted(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId
);

```

This is emitted when a seller **cancels** their listing.

This event helps:

- UIs stop showing expired or removed listings
- Indexers update their databases
- Everyone stay in sync on what’s actually for sale

---

### 🛠️ 4. `FeeUpdated`

```solidity

event FeeUpdated(
    uint256 newMarketplaceFee,
    address newFeeRecipient
);

```

This event logs when the **marketplace owner changes fee settings**.

That includes:

- The **new fee** (as basis points, e.g. 250 = 2.5%)
- The **new recipient address** where fee ETH will be sent

It’s mainly useful for admin panels, DAO-controlled platforms, or transparency for users.

---

## 🏗️6 Constructor – Bootstrapping the Marketplace

```solidity

constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
    require(_marketplaceFeePercent <= 1000, "Marketplace fee too high (max 10%)");
    require(_feeRecipient != address(0), "Fee recipient cannot be zero");

    owner = msg.sender;
    marketplaceFeePercent = _marketplaceFeePercent;
    feeRecipient = _feeRecipient;
}

```

---

### 🧠 What’s the Goal?

When someone deploys this contract, we want them to:

- Set how much **fee** the marketplace will take (e.g., 2.5%)
- Decide **where** those fees should go (e.g., to a DAO treasury or dev wallet)
- Automatically become the **owner/admin** of the contract

---

### 🔍 Line-by-Line Breakdown

---

### ✅ Fee Validation

```solidity

require(_marketplaceFeePercent <= 1000, "Marketplace fee too high (max 10%)");

```

- Prevents crazy fee settings at deployment.
- The fee is in **basis points**, where:
  - `1000` = 10%
  - `500` = 5%
  - `250` = 2.5%
- This line ensures the deployer can’t set something ridiculous like 99%.

---

### ✅ Fee Recipient Check

```solidity

require(_feeRecipient != address(0), "Fee recipient cannot be zero");

```

We’re making sure the deployer passes in a **valid ETH address** to receive marketplace fees.

> Setting it to the zero address (0x000...000) would make fees disappear forever — so we block that.

---

### 👑 Set Owner

```solidity

owner = msg.sender;

```

The person who deployed the contract becomes the **admin/owner**.

Why this matters:

- Only the owner can update fees or change the fee recipient
- It’s your way of saying: “This person controls the marketplace settings”

---

### 💰 Set Fee Settings

```solidity

marketplaceFeePercent = _marketplaceFeePercent;
feeRecipient = _feeRecipient;

```

- `marketplaceFeePercent`: How much the platform takes from every sale
- `feeRecipient`: Where that fee gets sent

Once these are set, the marketplace is ready to handle listings and sales.

## 🛡️ 7`onlyOwner` Modifier – Locking Down Admin Functions

```solidity

modifier onlyOwner() {
    require(msg.sender == owner, "Only owner");
    _;
}

```

---

### 🧠 What’s a Modifier?

In Solidity, a **modifier** is like a reusable guard clause.

You can attach it to a function to **require certain conditions before that function runs**.

It helps keep your code **clean**, **reusable**, and **easy to read**.

---

### 🔍 Line-by-Line Breakdown

---

### ✅ Check Who’s Calling

```solidity

require(msg.sender == owner, "Only owner");

```

This line makes sure the function can **only be called by the owner** — the address that deployed the contract.

- `msg.sender` is the address trying to call the function
- If it’s not equal to `owner`, the function is **stopped immediately**
- The error message `"Only owner"` is returned

This is your **access control** mechanism.

---

### 📦 Continue the Function

```solidity

_;

```

This funny little underscore means:

> “If the require check passed, now go ahead and run the rest of the function.”

## 💸8 `setMarketplaceFeePercent()` – Update the Marketplace Fee

```solidity

function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
    require(_newFee <= 1000, "Marketplace fee too high");
    marketplaceFeePercent = _newFee;
    emit FeeUpdated(_newFee, feeRecipient);
}

```

---

### 🧠 What Does It Do?

This function allows the **owner of the contract** to change the **marketplace fee** (the percentage the platform takes on every sale).

It’s useful for:

- Adjusting fees as your platform grows
- Reducing fees during promotions
- Increasing fees to sustain operations
- Responding to community governance, if run by a DAO

---

### 🔍 Line-by-Line Breakdown

---

### 🔐 Access Restriction

```solidity

external onlyOwner

```

- `external`: Means this function is meant to be called from outside the contract (like through a frontend or by the owner directly).
- `onlyOwner`: Ensures that **only the admin** can call it — thanks to the modifier we just covered.

---

### ✅ Input Check

```solidity

require(_newFee <= 1000, "Marketplace fee too high");

```

- Prevents setting unreasonably high fees.
- The fee is in **basis points**, so:
  - `1000` = 10%
  - `100` = 1%
- If `_newFee` is greater than 1000, the transaction is reverted.

This keeps the marketplace from becoming abusive or unusable.

---

### 📝 Update State

```solidity

marketplaceFeePercent = _newFee;

```

This sets the new value, updating the **global fee percentage** used in all future sales.

It **does not** affect existing listings — only new purchases going forward.

---

### 📢 Emit Event

```solidity

emit FeeUpdated(_newFee, feeRecipient);

```

This fires an event so that:

- Frontends can pick up the change and update the UI
- Auditors and users can see that the fee was changed
- You get on-chain transparency for every fee adjustment

---

## 🏦 9 `setFeeRecipient()` – Update Where the Marketplace Fees Go

```solidity

function setFeeRecipient(address _newRecipient) external onlyOwner {
    require(_newRecipient != address(0), "Invalid fee recipient");
    feeRecipient = _newRecipient;
    emit FeeUpdated(marketplaceFeePercent, _newRecipient);
}

```

---

### 🧠 What’s This For?

In any NFT marketplace, the **fee recipient** is the address that collects the marketplace’s share of every sale.

This might be:

- A **founder's wallet**
- A **DAO treasury**
- A **multisig** managed by a team
- Or even a **smart contract** that splits revenue further

This function lets the marketplace **adapt over time** — whether for security upgrades, decentralization, or shifting revenue to a community-controlled contract.

---

### 🔍 Line-by-Line Breakdown

---

### 🔐 Restrict to Owner

```solidity

external onlyOwner

```

Just like before:

- `external` = can only be called from outside the contract
- `onlyOwner` = **only the admin** can update the fee recipient

---

### ✅ Validate the New Address

```solidity

require(_newRecipient != address(0), "Invalid fee recipient");

```

- Checks that the new address is **not** the zero address (`0x000...000`).
- If it is, we revert the transaction to avoid “burning” future fees by accident.

> This is a simple but important safeguard.

---

### 📝 Save the New Address

```solidity

feeRecipient = _newRecipient;

```

We update the contract’s internal state — now all future marketplace fees will be sent to this new address.

---

### 📢 Emit Update Event

```solidity

emit FeeUpdated(marketplaceFeePercent, _newRecipient);

```

This reuses the `FeeUpdated` event — even though only the recipient changed.

This helps:

- Frontends reflect the change instantly
- Indexers track admin actions
- Users know where fees are going

---

## 🏷️ 10 `listNFT()` – List Your NFT for Sale

###

```solidity

function listNFT(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    address royaltyReceiver,
    uint256 royaltyPercent
) external {
    require(price > 0, "Price must be above zero");
    require(royaltyPercent <= 1000, "Max 10% royalty allowed");
    require(!listings[nftAddress][tokenId].isListed, "Already listed");

    IERC721 nft = IERC721(nftAddress);
    require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
    require(
        nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
        "Marketplace not approved"
    );

    listings[nftAddress][tokenId] = Listing({
        seller: msg.sender,
        nftAddress: nftAddress,
        tokenId: tokenId,
        price: price,
        royaltyReceiver: royaltyReceiver,
        royaltyPercent: royaltyPercent,
        isListed: true
    });

    emit Listed(msg.sender, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent);
}

```

---

## 🧠 What Does It Do?

This function allows any user to **list an NFT they own** for sale on the marketplace.

It checks:

- That the user owns the NFT
- That the NFT is approved for marketplace transfers
- That the price and royalty settings are valid

Once validated, it stores the listing on-chain and emits an event so frontends can show it in the marketplace UI.

---

## 📥 Inputs – What the Function Takes

```solidity

function listNFT(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    address royaltyReceiver,
    uint256 royaltyPercent
)

```

| Parameter         | What It Represents                                             |
| ----------------- | -------------------------------------------------------------- |
| `nftAddress`      | The **ERC-721 contract** address of the NFT                    |
| `tokenId`         | The **unique ID** of the NFT you're listing                    |
| `price`           | The amount of **ETH (in wei)** you want to sell it for         |
| `royaltyReceiver` | The address that should receive a **royalty** on the sale      |
| `royaltyPercent`  | How much royalty to give (in **basis points**, e.g., 500 = 5%) |

---

## 🔍 Line-by-Line Breakdown

---

### ✅ Step 1: Basic Validations

```solidity

require(price > 0, "Price must be above zero");
require(royaltyPercent <= 1000, "Max 10% royalty allowed");
require(!listings[nftAddress][tokenId].isListed, "Already listed");

```

- You must list for a **non-zero price**
- Royalties must be **≤10%** to keep things reasonable
- NFT must **not already be listed** (to avoid overwriting or duplicate entries)

---

### 🔗 Step 2: Interact with the NFT

```solidity

IERC721 nft = IERC721(nftAddress);

```

We cast the address into an `IERC721` contract interface so we can call standard ERC-721 functions like:

- `ownerOf`
- `getApproved`
- `isApprovedForAll`

---

### 👑 Step 3: Check NFT Ownership & Approval

```solidity

require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");

```

Ensures the caller **actually owns the NFT** they’re trying to list.

This protects against someone listing NFTs they don’t own.

---

```solidity

require(
    nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
    "Marketplace not approved"
);

```

The marketplace **must be approved** to transfer the NFT on the user's behalf.

This is required so the contract can send the NFT to the buyer when it’s sold.

---

### 📦 Step 4: Save Listing Info On-Chain

```solidity

listings[nftAddress][tokenId] = Listing({
    seller: msg.sender,
    nftAddress: nftAddress,
    tokenId: tokenId,
    price: price,
    royaltyReceiver: royaltyReceiver,
    royaltyPercent: royaltyPercent,
    isListed: true
});

```

We create a `Listing` struct and store it in our nested `listings` mapping.

This is now a **live listing** on the marketplace — discoverable by anyone.

---

### 📢 Step 5: Emit an Event

```solidity

emit Listed(msg.sender, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent);

```

This logs the listing on-chain so:

- UIs can display it
- Indexers (like The Graph) can track it
- Users can see activity in real time

---

## 🛍️ 11 `buyNFT()` – Buying an NFT With ETH

this is the **heart of the marketplace** right here.

When someone finds an NFT they like and clicks “Buy,” this function is what actually makes the trade happen.

Let’s walk through it like we’re explaining it to someone buying an NFT for the first time — and also coding the backend to make it work.

```solidity

function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
    Listing memory item = listings[nftAddress][tokenId];
    require(item.isListed, "Not listed");
    require(msg.value == item.price, "Incorrect ETH sent");
    require(
        item.royaltyPercent + marketplaceFeePercent <= 10000,
        "Combined fees exceed 100%"
    );

    uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
    uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
    uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

    // Pay marketplace
    if (feeAmount > 0) {
        payable(feeRecipient).transfer(feeAmount);
    }

    // Pay creator royalty
    if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
        payable(item.royaltyReceiver).transfer(royaltyAmount);
    }

    // Pay seller
    payable(item.seller).transfer(sellerAmount);

    // Transfer NFT to buyer
    IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

    // Clean up listing
    delete listings[nftAddress][tokenId];

    emit Purchase(
        msg.sender,
        nftAddress,
        tokenId,
        msg.value,
        item.seller,
        item.royaltyReceiver,
        royaltyAmount,
        feeAmount
    );
}

```

---

## 🧠 What Does It Do?

This function:

- Accepts ETH from a buyer
- Splits it between the seller, the creator (for royalties), and the platform (as a fee)
- Transfers the NFT to the buyer
- Deletes the listing
- Emits an event to let the world know a purchase happened

All in a single transaction. No manual steps. No off-chain confirmations.

---

## 🧩 Let’s Break It Down

---

### 🛡️ Function Header

```solidity

function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant

```

- `external`: Called by users from outside the contract.
- `payable`: So the buyer can send ETH.
- `nonReentrant`: Uses `ReentrancyGuard` to protect against reentrancy attacks — a common vulnerability in functions that send ETH.

---

### 📄 Load the Listing

```solidity

Listing memory item = listings[nftAddress][tokenId];

```

We fetch the listing from storage into memory, so we can read its details (price, seller, royalty info, etc.).

---

### 🔒 Validations

```solidity

require(item.isListed, "Not listed");
require(msg.value == item.price, "Incorrect ETH sent");
require(
    item.royaltyPercent + marketplaceFeePercent <= 10000,
    "Combined fees exceed 100%"
);

```

- Is this NFT even listed?
- Did the buyer send **exactly** the amount of ETH required?
- Does the combined royalty + platform fee stay under 100%?

> Without that last check, someone could set royalties + fees to 110% and break the payout math.

---

### 💰 Calculate Payouts

```solidity

uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

```

We break the total ETH (`msg.value`) into three buckets:

- Marketplace fee
- Creator royalty
- Seller's actual earnings

All calculated in **basis points** for precise fee logic.

---

### 🏦 Distribute the Funds

### Pay the Marketplace

```solidity

if (feeAmount > 0) {
    payable(feeRecipient).transfer(feeAmount);
}

```

ETH goes to the `feeRecipient` — this could be the platform, a DAO, or even a dev wallet.

---

### Pay the Creator (Optional)

```solidity

if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
    payable(item.royaltyReceiver).transfer(royaltyAmount);
}

```

If the listing has royalty info, the specified address gets a cut.

> This supports creator earnings on secondary sales — a huge feature in the NFT space.

---

### Pay the Seller

```solidity

payable(item.seller).transfer(sellerAmount);

```

Whatever’s left after fees and royalties goes to the person who listed the NFT.

---

### 📦 Transfer the NFT

```solidity

IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

```

The contract **moves the NFT** from the seller to the buyer using the standard ERC-721 transfer function.

> This only works because the seller approved the marketplace during listing.

---

### 🧹 Clean Up the Listing

```solidity

delete listings[nftAddress][tokenId];

```

Once the NFT is sold, we remove the listing from storage so it’s no longer shown as “for sale.”

---

### 📢 Emit the Purchase Event

```solidity

emit Purchase(
    msg.sender,
    nftAddress,
    tokenId,
    msg.value,
    item.seller,
    item.royaltyReceiver,
    royaltyAmount,
    feeAmount
);

```

This logs the full details of the transaction — so UIs and indexers can track sales, fees, and royalties.

---

## ❌12 `cancelListing()` – Removing an NFT From Sale

###

```solidity

function cancelListing(address nftAddress, uint256 tokenId) external {
    Listing memory item = listings[nftAddress][tokenId];
    require(item.isListed, "Not listed");
    require(item.seller == msg.sender, "Not the seller");

    delete listings[nftAddress][tokenId];
    emit Unlisted(msg.sender, nftAddress, tokenId);
}

```

---

## 🧠 What Does It Do?

This function lets the **seller** of an NFT remove it from the marketplace **before it's sold**.

It’s useful when:

- You change your mind about selling
- You want to relist at a new price
- You accidentally listed the wrong NFT

The function ensures **only the original seller** can unlist — and once done, the NFT will no longer show up as available for purchase.

---

## 📥 Inputs

```solidity

(address nftAddress, uint256 tokenId)

```

Just like with listing or buying:

- `nftAddress` = the contract of the NFT
- `tokenId` = the specific NFT being unlisted

---

## 🔍 Line-by-Line Breakdown

---

### 📄 Step 1: Load the Listing

```solidity

Listing memory item = listings[nftAddress][tokenId];

```

Fetch the listing details from storage into memory so we can inspect them.

---

### 🛡️ Step 2: Validations

```solidity

require(item.isListed, "Not listed");

```

- If the NFT isn’t listed, you can’t cancel it.
- This prevents unnecessary deletes or misleading UI updates.

```solidity

require(item.seller == msg.sender, "Not the seller");

```

- Only the original **seller** can cancel their listing.
- This protects against random users or even the buyer trying to mess with listings.

---

### 🧹 Step 3: Delete the Listing

```solidity

delete listings[nftAddress][tokenId];

```

This removes the listing from the `listings` mapping entirely.

After this, the NFT is no longer for sale and won’t appear in frontend marketplaces or APIs.

---

### 📢 Step 4: Emit Event

```solidity

emit Unlisted(msg.sender, nftAddress, tokenId);

```

We log the action publicly, which lets:

- UIs update in real-time
- Users see a clear transaction history
- Indexers track the listing status

## 📦 `getListing()` – View Listing Details

```solidity

function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
    return listings[nftAddress][tokenId];
}

```

### 🧠 What It Does

This is a **read-only helper function** that lets anyone (like a frontend or another contract) fetch details about a specific listing.

- It doesn’t cost gas when called externally (because it's `view`)
- It returns the full `Listing` struct for a given NFT

### 🖼️ When Would You Use It?

- A marketplace frontend wants to show all the details of a listed NFT
- A buyer wants to preview the price and royalty before purchasing
- A script or bot wants to check what’s listed and filter for deals

---

## 🛑 `receive()` – Reject Direct ETH Transfers

```solidity

receive() external payable {
    revert("Direct ETH not accepted");
}

```

### 🧠 What It Does

This function is triggered when someone **sends ETH directly to the contract** without calling a function.

By default, Solidity allows contracts to receive ETH this way — but in our case, we **don’t want that**.

This function **rejects** such transfers by calling `revert()`.

> This protects against:
>
> - Accidental ETH transfers
> - Users thinking they’re buying something by just sending ETH
> - ETH getting stuck in the contract forever

---

## 🧟 `fallback()` – Reject Unknown Function Calls

```solidity

fallback() external payable {
    revert("Unknown function");
}

```

### 🧠 What It Does

The `fallback()` function is called when:

- Someone calls a function that doesn’t exist in the contract
- Or sends ETH without triggering `receive()`

In both cases, we **don’t want to accept the call or the ETH**, so we immediately revert with an error.

> This prevents accidental misuse and ensures users don’t lose ETH by calling typos like byuNFT() instead of buyNFT().

# 🛠️ Testing Your NFT Marketplace on Remix

You’ve built an actual digital store with your smart contract. Now let’s fire it up and see it in action on Remix.

You’ll be able to:

- Mint NFTs
- List them for sale
- Buy them using ETH
- Cancel listings
- Watch everything update in real-time

---

## 📦 Step 1: Load Your Contracts

You’ll need **two contracts**:

### 1. `SimpleNFT.sol` (The one that you built earlier)

> ✅ This lets you mint NFTs to your own wallet.

---

### 2. `NFTMarketplace.sol` (your marketplace)

Paste the **full Marketplace contract** you built earlier.

✅ Make sure both contracts compile without errors using the Solidity Compiler tab.

---

## 🚀 Step 2: Deploy Contracts

1. Go to the **Deploy & Run** tab in Remix.
2. Set **Environment** to `Remix VM (London)` (for local testing).
3. Deploy `SimpleNFT` — copy its address.
4. Deploy `NFTMarketplace` with these constructor values:
   - Fee percent: `250` (for 2.5%)
   - Fee recipient: your own Remix wallet address (you’ll see it top right)

---

## 🎨 Step 3: Mint Some NFTs

1. Expand your deployed `SimpleNFT` contract.
2. Call the `mint()` function twice to mint two NFTs (IDs 0 and 1).
3. Call `ownerOf(0)` and `ownerOf(1)` to confirm you own them.

---

## ✅ Step 4: Approve the Marketplace

Before the marketplace can list or sell your NFTs, you need to **approve** it.

1. In `SimpleNFT`, call:
   - `setApprovalForAll(marketplaceAddress, true)`
   - (Replace `marketplaceAddress` with the actual address of your deployed marketplace)

---

## 🏷️ Step 5: List an NFT for Sale

Now go to your deployed `NFTMarketplace` contract.

1. Call `listNFT()` with:
   - `nftAddress`: your `SimpleNFT` contract address
   - `tokenId`: `0`
   - `price`: `1000000000000000000` (this is 1 ETH in wei)
   - `royaltyReceiver`: your own address
   - `royaltyPercent`: `500` (5%)

✅ This NFT is now live and listed.

---

## 🛒 Step 6: Buy the NFT

Switch to another account in Remix (top-right dropdown).

In the **Marketplace contract**, call `buyNFT()` with:

- `nftAddress`: your `SimpleNFT` address
- `tokenId`: `0`

👇 In the value field above the call button:

- Enter `1` ETH: `1000000000000000000`

✅ Boom — your NFT was purchased!

- Seller got paid
- Royalty went to the creator
- Fee went to the platform
- NFT transferred to the buyer

---

## ❌ Step 7: Try Canceling a Listing

- Mint a third NFT (`mint()` again).
- Approve the marketplace if needed.
- List `tokenId 2`.

Then call `cancelListing()` with:

- `nftAddress`
- `tokenId`: `2`

✅ You’ll see the listing disappear (check via `getListing()`).

---

## 🧠 Optional Debug Tips

- Use `getListing(nftAddress, tokenId)` to view listing info
- Use `ownerOf(tokenId)` in `SimpleNFT` to track NFT transfers
- Check the Remix **console logs and transactions** for all ETH movements

---

## 🎉 You Did It

You’ve just:

- Minted NFTs
- Listed them for sale
- Bought them with royalties and fees
- Canceled listings
- Fully tested your own on-chain NFT store

All without needing a backend, database, or frontend.
