# Day 2 – Solidity Challenge 🚀

## 📌 Task: Enhanced User Profile Smart Contract

Today’s challenge is about building a **basic user profile system** on the blockchain.
We extend the Day 1 example (storing just `name` and `bio`) by adding more detailed profile information.

---

## 🎯 What You’ll Learn

* How to use **structs** to group related data.
* How to map each Ethereum **address to a profile**.
* How to **store, update, and retrieve multiple fields** (like name, bio, age, location, profile picture).
* How to use **events** to log profile updates on-chain.

---

## 📖 Contract Overview

The contract allows users to:

1. Create or update their profile with:

   * `username`
   * `bio`
   * `age`
   * `location`
   * `profilePic` (IPFS hash or URL)
   * `joinedOn` (auto timestamp when updated)
2. Retrieve any user’s profile by their wallet address.

---

## 📝 Example

```solidity
// Save profile
setProfile("Alice", "I build dApps", 25, "Bangalore, India", "ipfs://QmHashOfPic");

// Retrieve profile
getProfile(aliceAddress);

// Returns ->
("Alice", "I build dApps", 25, "Bangalore, India", "ipfs://QmHashOfPic", 1696182954)
```

---

## ⚡ Key Features

* **Struct-based storage** for profile data.
* **Mapping** from `address => Profile`.
* **Event logs** for frontend dApps to track changes.
* **Timestamping** when profile is created/updated.

---

## ✅ Learning Outcome

By completing this task, you’ll understand how to:

* Store multiple pieces of user data in one place.
* Use mappings and structs effectively.
* Design a reusable **profile system** for dApps like social networks, identity management, or marketplaces.
