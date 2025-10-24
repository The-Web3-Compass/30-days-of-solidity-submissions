// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
==========================================================
🧠 Summary of Key Solidity Concepts (from Q&A discussion)
==========================================================

1️⃣  [private / public / external / internal]
    • `private`  → only visible inside the same contract.
    • `internal` → visible to the contract and its children.
    • `public`   → visible to everyone.
    • `external` → can only be called from outside (not internally).

2️⃣  [constructor]
    • Runs once during contract deployment.
    • Used to initialize contract state variables.
    • Example: sets the owner, item, and auction end time.

3️⃣  [require()]
    • Works like Python’s `assert`, but blockchain-safe.
    • If condition fails → reverts the transaction and refunds remaining gas.
    • Used to enforce logic like:
        - auction not ended yet
        - bid amount > previous bid
        - only non-winners can withdraw

4️⃣  [block.timestamp]
    • Gives the current Unix time (seconds).
    • Commonly used for time-based logic.
    • Example: `require(block.timestamp < auctionEndTime)` ensures auction is still open.

5️⃣  [msg.sender / msg.value]
    • `msg.sender`: address calling the function.
    • `msg.value`: amount of ETH (in wei) sent with the transaction.
    • ⚠️ In this code, bidders *do not actually send Ether*, because:
        - `bid()` is NOT marked `payable`
        - it only records numbers, not real funds.
    • To make bidders pay:
        Change `function bid(uint amount)` → `function bid() external payable`
        Then use `msg.value` instead of the manual `amount`.

6️⃣  [Why no float in Solidity]
    • Solidity has NO floating-point (`float`, `double`) types.
    • Use integer math with a scale factor (e.g., multiply by 10⁶) for precision.
    • Scale can use: A * FACTOR / PRECISION (a larger scaling factor provides better precision)

7️⃣  [withdrawBid()]
    • You cannot use Python-style `if (msg.sender in bidders)` or `pop(value)`.
    • Must manually iterate through the array.
    • Always reset the mapping first to prevent re-entrancy.
    • If it’s a real ETH auction, refund Ether with `transfer()` or `call()`.

8️⃣  [Real auction vs tutorial]
    • Tutorial version = stores numbers only (no payment logic).
    • Real version     = uses `payable`, `msg.value`, and transfers ETH safely.
    • Also needs refund logic for outbid users and payout to the owner at end.

==========================================================
🚀 This file now serves both as your code and a study reference.
==========================================================
*/

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    uint public startBid = 100;

    address private highestBidder; // Private: only visible inside this contract
    uint private highestBid;       // Private: accessible via getWinner()

    bool public ended;

    mapping(address => uint) public bids;
    address[] public bidders;

    // -----------------------------------------------------
    // 🔹 constructor
    // Initializes owner, item name, and sets auction end time.
    // Runs only once when the contract is deployed.
    // -----------------------------------------------------
    constructor(string memory _item, uint _biddingTime) {
        owner = msg.sender;                               // who deployed the contract
        item = _item;                                     // what’s being auctioned
        auctionEndTime = block.timestamp + _biddingTime;  // when auction ends
    }

    // -----------------------------------------------------
    // 🔹 bid()
    // Currently: simulated bidding (no actual ETH transfer)
    // To make this a real auction, make it payable and use msg.value.
    // -----------------------------------------------------
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > startBid, "Bid amount must be greater than startBid.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        // Track new bidders
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        // Record bid amount (just a number, not real money)
        bids[msg.sender] = amount;

        // Update the highest bid and bidder
        // Note: condition below enforces at least 5% increase threshold
        if (amount > highestBid / 100 * 105) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    // -----------------------------------------------------
    // 🔹 withdrawBid()
    // Allows non-winning bidders to remove themselves from the list.
    // (In a real ETH auction, this should transfer their ETH back.)
    // -----------------------------------------------------

    /*
    ============================================
    ⚠️ Important implications of Solidity mappings
    ============================================

    1. You CANNOT check if a key "exists" directly.
       - Accessing a non-existent key simply returns the default value.
       - To infer existence, compare against that default:
         Example:
             if (bids[user] != 0) {
                 // user has placed a bid
             }

    2. Deleting an entry sets it back to its default.
         delete bids[user];
       is equivalent to:
         bids[user] = 0;

    3. Mappings cannot be iterated over.
       - Solidity does not store keys or length for mappings.
       - If you need to list all keys (e.g. all bidders),
         maintain a separate array like `address[] bidders`.

    4. Reading a mapping with an unused key is always safe.
       - It will just return the default value (e.g. 0 for uint).

    5. Default values by type:
       • uint / int   → 0
       • bool         → false
       • address      → 0x000...0
       • bytes32      → 0x0
       • struct       → all members default
    */

    function withdrawBid() external {
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw");
        uint amount = bids[msg.sender];
        require(amount > 0, "No bid to withdraw");

        // Reset mapping entry (reentrancy safety)
        bids[msg.sender] = 0;

        // Remove from bidders array (gas-expensive O(n) operation)
        for (uint i = 0; i < bidders.length; i++) {
            if (bidders[i] == msg.sender) {
                bidders[i] = bidders[bidders.length - 1]; // move last to current slot
                bidders.pop();                            // remove last
                break;
            }
        }

        // ⚠️ If this were a real ETH auction:
        // payable(msg.sender).transfer(amount);
    }

    // -----------------------------------------------------
    // 🔹 endAuction()
    // Marks auction as finished. In a real auction, you’d also
    // transfer the winning bid to the owner here.
    // -----------------------------------------------------
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");
        ended = true;
    }

    // -----------------------------------------------------
    // 🔹 getAllBidders()
    // Returns the list of all addresses who placed at least one bid.
    // -----------------------------------------------------
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // -----------------------------------------------------
    // 🔹 getWinner()
    // Reveals winner and winning bid amount after auction ends.
    // -----------------------------------------------------
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
}
