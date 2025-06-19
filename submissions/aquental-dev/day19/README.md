# Day 19 of 30

Concepts

- ecrecover
- verifying signatures
- basic authentication

Progression

- Introduces cryptographic authentication.

Example Application

Build a secure signature-based entry system for a private Web3 event, like a conference, workshop, or token-gated meetup. Instead of storing an on-chain whitelist of attendees, your backend or event organizer signs a message for each approved guest. When attendees arrive, they submit their signed message to the smart contract to prove they were invited. The contract uses `ecrecover` to verify the signature on-chain, confirming their identity without needing any prior on-chain registration. This pattern drastically reduces gas costs, keeps the contract lightweight, and mirrors how many real-world events handle off-chain approvals with on-chain validation — a practical Web3 authentication flow.

[sepolia Contract](https://sepolia.etherscan.io/address/0x58b2e80281805e5fe2bc1e54eb150a55b8112b0e#code)

---

## testing

- deploy with address `0xc2572E65d61aFa5DD6BcFAC57305Bb59EBD9A54E`
- on the script tab, run `scripts/SignThisScript.ts`

```json
Message Hash:
0x7f4cf8ef25b6d8689604515dbd05a6faa78bfdf5412750b985eb6c209a4e3b8c
Signature:
0xbacea926407fa30c69d4cd1f350c23498997a92443fcb3d8136197f7b562acf43900ef892a00fda1a0bfa217b7a4fa8249dc5fec5013e0dfd5c0c47373a50f4e1b
```

- call `enterEvent` with the parameters from above: [sepolia transaction](https://sepolia.etherscan.io/tx/0xc22259f3f9963c77652ed580d7f6cce4ee0554b6ea3362aad7d303aa794956a5)
- call `organizer`:

```jason
0: address: 0xc2572E65d61aFa5DD6BcFAC57305Bb59EBD9A54E
```
