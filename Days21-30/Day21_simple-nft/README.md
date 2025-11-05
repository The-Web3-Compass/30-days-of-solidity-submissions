## **Day 21 - Simple NFT**

This project focuses on building a simple NFT smart contract from scratch using Solidity and Foundry.
The NFT stores metadata hosted on IPFS via Pinata and can be minted, transferred, and verified through Foundry tests.
No external libraries like OpenZeppelin were used — all ERC-721 functionalities were implemented manually.

---

### **Smart Contract Explanation (`src/SimpleNFT.sol`)**

The contract defines a minimal ERC-721–style NFT system.
It includes all core NFT operations such as minting, transferring, and metadata linking.

**Main features:**

* Each token is assigned a unique ID using an internal counter.
* Ownership and balances are stored in mappings.
* The `mint()` function allows anyone to mint an NFT with an IPFS metadata URI.
* Transfers are restricted to the token owner or approved users.
* A manual `tokenURI()` function returns the stored IPFS metadata link.
* The contract also includes safe transfer checks with the ERC721 receiver interface.

This helped in understanding how ERC-721 tokens work under the hood without using any external contracts.

---

### **Testing (`test/SimpleNFT.t.sol`)**

The tests were written in Solidity using Foundry’s testing framework.

Each test verifies a specific part of the contract:

* **`testNameAndSymbol`** – Checks if the name and symbol are correctly set during deployment.
* **`testMintIncrementsBalance`** – Verifies that minting increases the owner’s balance and stores ownership correctly.
* **`testTransferNFT`** – Tests NFT transfer between two users and verifies new ownership.
* **`testTokenURI`** – Confirms that the metadata URI is stored and returned correctly.
* **`test_RevertWhen_TransferNotAuthorized`** – Ensures that unauthorized transfers fail with a revert message.

All tests were executed successfully.

---

### **Pinata and IPFS Metadata**

The NFT metadata and image were uploaded to **Pinata** for decentralized storage.
These files were pinned to IPFS, and their CID links were used in the contract as metadata URIs.

**Pinata URLs used in the project:**

* **Metadata JSON:**
  https://turquoise-broad-tahr-484.mypinata.cloud/ipfs/bafkreig6tn7zrltyg62wivwpii6xfwmfy7i2fdtkeueyfmvfwasjoplqfe

* **NFT Image:**
 https://turquoise-broad-tahr-484.mypinata.cloud/ipfs/bafkreidrf7t5l3utfhcrfu2rraftrrqisv4rsmum6keuie4x6ntdnf2sqy

The `metadata.json` file contained details like:

```json
{
  "name": "My First NFT",
  "description": "A simple NFT stored on IPFS using Pinata",
  "image": "ipfs://QmExample1"
}
```

Screenshots of the metadata and image uploads are available in the `outputs/` folder:

* `nft image`
* `metadata json view`
* `pinata files`
* `vscode test 1`, `vscode test 2`, `vscode test 3`

---

### **Foundry Commands Used**

```bash
# Build the project
forge build

# Run tests with detailed logs
forge test -vv
```

---

### **Summary**

This project demonstrates how NFTs are built and tested without any external libraries.
By writing all ERC-721 functions manually, it provides a deep understanding of how minting, ownership, and metadata linking work.
The integration with **Pinata and IPFS** shows how real-world NFTs connect on-chain data with decentralized file storage.

---

## End of the Project.
