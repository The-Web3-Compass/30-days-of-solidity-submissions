# Day 26 - NFT Marketplace (SimpleNFT + Marketplace)

## 1. Overview

Built a minimal NFT Marketplace consisting of two smart contracts:

1. **SimpleNFT.sol** - A basic ERC721 NFT contract that allows minting.
2. **NFTMarketplace.sol** - A marketplace where users can list their NFTs for sale, enforce royalties, update listings, cancel listings, and perform secure purchases.

Tested everything thoroughly in Remix: deployment, approvals, listing, verification, updates, and purchase flows. All outputs have been saved under the `outputs/` folder.

---

## 2. Done task:

* Created a new Foundry project for Day 26.
* Added two contracts inside `src/`: SimpleNFT.sol and NFTMarketplace.sol.
* Installed OpenZeppelin ERC721 libraries.
* Removed the `lib` folder before pushing to GitHub.
* Deployed both contracts in Remix.
* Approved marketplace using `setApprovalForAll`.
* Listed an NFT with royalties.
* Retrieved listing data.
* Tested error cases such as “Already Listed” and “Incorrect ETH Sent”.
* Successfully executed the purchase transaction.
* Captured all transaction outputs as screenshots.

---

## 3. Contract Explanations 

### **SimpleNFT.sol**

A minimal ERC721 NFT contract.

**Key Functions:**

* `constructor() ERC721("TestNFT", "TNFT")`
  Initializes the NFT name and symbol.

* `mint()`
  Mints a new NFT to `msg.sender`.
  Uses `_safeMint(msg.sender, nextId)` and increments `nextId`.

This contract only handles minting and ownership.

---

### **NFTMarketplace.sol**

Handles listing, buying, royalties, and marketplace fees.
Includes OpenZeppelin’s `ReentrancyGuard` for protection.

**State Variables:**

* `owner` – Contract owner.
* `marketplaceFeePercent` – Marketplace fee (basis points).
* `feeRecipient` – Address receiving marketplace fees.
* `struct Listing` – Contains seller, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent, and listing status.

**Key Functions:**

* `listNFT(nftAddress, tokenId, price, royaltyReceiver, royaltyPercent)`
  Creates a new listing.
  Requires caller to be NFT owner and ensures token is approved.

* `updateListing(nftAddress, tokenId, newPrice)`
  Allows seller to update the listing price.

* `cancelListing(nftAddress, tokenId)`
  Only seller can cancel the listing.

* `buyNFT(nftAddress, tokenId)`
  Handles the purchase:

  * Validates listing.
  * Checks correct ETH amount.
  * Calculates royalties and marketplace fee.
  * Sends payments to seller, royalty receiver, and feeRecipient.
  * Transfers the NFT to the buyer.
  * Marks listing as sold.

* `getListing(nftAddress, tokenId)`
  Returns listing details.

* `setMarketplaceFeePercent()`
  Owner-only.

* `setFeeRecipient()`
  Owner-only.

These functions cover the entire NFT trading lifecycle.

---

## 4. Foundry Commands Used

* `forge init`
  Creates new Foundry project.

* `forge build`
  Compiles all contracts.

* `forge test -vv`
  (Not used here for Day 26 - but normally used for tests).

* `rm -rf lib`
  Removed the lib folder before committing.

* `git add .`
  Staged all changes.

* `git commit -m "Day 26 - NFT Marketplace"`
  Saved the commit.

* `git pull origin main --rebase`
  Resolved remote changes before pushing.

* `git push origin main`
  Uploaded the project to GitHub.

---

## 5. Explanation of Output Screenshots

The `outputs/` folder contains the following execution records:

1. **Contract Deployment - NFTMarketplace**
   Marketplace deployed successfully.

2. **Contract Deployment - SimpleNFT**
   NFT contract deployed before listing or buying actions.

3. **Approve Marketplace (setApprovalForAll)**
   Required before listing NFTs.

4. **Check isApprovedForAll Result**
   Shows approval status as true.

5. **List NFT Transaction**
   NFT was successfully listed with price + royalty details.

6. **Get Listing - Raw Tuple Output**
   Confirms stored struct values: seller, price, royalties, isListed.

7. **Already Listed Error (Safety Check)**
   Marketplace prevented double-listing the same NFT.

8. **Buy NFT - Incorrect ETH Sent**
   Shows revert due to insufficient ETH.

9. **Buy NFT - Successful Transaction**
   Shows successful purchase, royalty transfer, seller payment, and NFT ownership update.

10. **Get Listing Output After Purchase**
    Shows listing is no longer active (isListed = false).

These outputs validate the entire workflow from listing -- buying -- verifying results.

---

## 6. Why We Removed `lib/`

The `lib/` folder contains full OpenZeppelin libraries installed via `forge install`.
It should not be committed because:

* It is heavy.
* It causes merge conflicts.
* Everyone can re-install libraries using `forge install`.

Have added `lib/` to `.gitignore` to prevent future issues.

---

## 7. Summary

A complete NFT trading mechanism using two interoperable contracts. Following were implemented:

* ERC721 minting
* Listing and royalty logic
* Secure purchasing using ReentrancyGuard
* Fee distribution
* Proper testing both with valid and invalid flows
---

# End of the Project.
