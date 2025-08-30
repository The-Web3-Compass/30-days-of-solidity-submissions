# Day 21 of 30

Concepts

- ERC721 basics
- minting NFTs
- metadata storage

Progression

- Introduces NFT standards.

Example Application

Create your own digital collectibles (NFTs)! You'll learn how to make unique digital items by implementing the ERC721 standard and storing metadata. It's like creating digital trading cards, demonstrating NFT creation.

[SimpleNFT - sepolia Contract](https://sepolia.etherscan.io/address/0xf1d93ddae83b2e0869581de0a301f84ae6c81f4a)

---

- call `safemint` passing a wallet address : [trx](https://sepolia.etherscan.io/tx/0x93c3bd72ee88bc988978a5e081263559ba08e9dbf461543824e240e9052fd309)
- call `ownerOf` passing the tokenId (starts at 0 for the first minted NFT).

```
from	0x66790dbCAa417dC4244b3108036DCB6D98b805b0
to	SimpleNFT.ownerOf(uint256) 0xf1D93ddAe83b2E0869581de0a301f84AE6c81F4A
input	0x635...00000
output	0000000000001021211318817065125196367549831092031091521845176
decoded input	{
	"uint256 tokenId": "0"
}
decoded output	{
	"0": "address: 0x66790dbCAa417dC4244b3108036DCB6D98b805b0"
}
logs	[]
raw logs	[]
```
