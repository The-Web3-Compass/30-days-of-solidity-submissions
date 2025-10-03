# Day 3 of 30 Days of Solidity Challenge – Polling Station 🗳️

## 📌 Task

For Day 3, I built a **simple polling station smart contract**. Users can vote for their favorite candidates, and the contract keeps track of votes in a transparent and tamper-proof way.

This task focuses on:

* Using **arrays** to store candidate details.
* Using **mappings** to record who has voted.
* Implementing a basic digital voting booth in Solidity.

---

## 🚀 How It Works

1. Deploy the contract with candidate names, for example: **Alice, Bob, Charlie**.
2. Each user can cast a vote by choosing a candidate.
3. Every voter’s address is stored in a mapping to prevent **double voting**.
4. Results can be checked anytime by retrieving candidate details and their vote counts.

---

## 📚 Key Learnings

* **Arrays** are useful for storing structured data like a candidate list.
* **Mappings** are powerful for tracking unique actions, such as whether someone has voted.
* Combining **arrays, mappings, and structs** helps in building real-world applications.
* **Events** can be used to log important actions like casting a vote, making the system more transparent.

---

🔥 This wraps up **Day 3 of 30 Days of Solidity Challenge**.
Next up: building even more advanced smart contracts with new concepts!

