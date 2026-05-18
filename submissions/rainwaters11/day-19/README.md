# Day 19: Digital Signatures & Event Entry

## Overview
For Day 19, we've implemented signature-based access control rules for token-gated events.

## Concepts Added
- Signature verification utilizing cryptographic hashing (`keccak256`) and the Ethereum Signed Message prefix (`\x19Ethereum Signed Message:\n32`).
- Extracting ECDSA signer parameters (`r`, `s`, `v`) with fallback assembly blocks using `ecrecover`.
- Limiting event capacity globally within check-in boundaries (`maxAttendees`).

## Contracts
- `EventEntry.sol`: Contains all the business logic, signature hash verifications, and event configurations.
