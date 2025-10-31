## Day 19 - SignThis | Event Attendee Verification using Digital Signatures

### Project Overview

This project implements a signature-based authentication system for private Web3 events such as conferences, workshops, or token-gated meetups.
Instead of maintaining an on-chain whitelist, each approved attendee receives an off-chain signed message from the event organizer.
Upon arrival, the attendee submits the signature on-chain to verify their invitation.

The smart contract verifies the authenticity of the signature using `ecrecover`, confirming that the message was signed by the organizer and that the event has not yet expired.
This design saves gas, reduces complexity, and reflects real-world off-chain approval with on-chain validation.

---

### Folder Structure

**src/** – Contains the core smart contract `EventEntry.sol` which handles the signing and on-chain verification of attendees.
**test/** – Includes Foundry test cases (`EventEntry.t.sol`) verifying signature creation, validity, and rejection of invalid entries.
**script/** – Contains a sample `signInvite.js` script to demonstrate how the backend organizer can sign messages using a private key.
**lib/** – Forge standard library (`forge-std`) for testing utilities.
**foundry.toml** – Project configuration file specifying compiler version and libraries used.

---

### Smart Contract Summary

**Contract:** `EventEntry.sol`

* The organizer deploys the contract with:

  * `eventName`: name of the event
  * `eventTime`: UNIX timestamp for event end time
  * `maxAttendees`: maximum allowed attendees
* The organizer signs the attendee’s wallet address off-chain.
* The attendee calls `checkIn(bytes signature)` to verify and mark attendance.
* The contract uses `ecrecover` to verify that the message was signed by the correct organizer.
* Once verified, attendance is recorded on-chain.

---

### Foundry Commands Used

**1. Build the project**

```bash
forge build
```

**Sample Output:**

```
[⠔] Compiling 21 files with Solc 0.8.30
Compiler run successful!
```

---

**2. Run the tests**

```bash
forge test -vv
```

**Sample Output:**

```
Ran 2 tests for test/EventEntry.t.sol:EventEntryTest
[PASS] testCheckInWorks() (gas: 82842)
[PASS] testRejectsInvalidSignature() (gas: 35697)
Suite result: ok. 2 passed; 0 failed; 0 skipped
```

---

**3. Start a local blockchain**

```bash
anvil
```

This provides 10 test accounts and private keys with local RPC running at
`http://127.0.0.1:8545`

---

**4. Deploy the contract manually using cast**

```bash
cast send \
--rpc-url http://127.0.0.1:8545 \
--private-key <organizer_private_key> \
--create "$BYTECODE" \
"Web3 Summit" <event_timestamp> 10
```

**Sample Output:**

```
contractAddress      0x5FbDB2315678afecb367f032d93F642f64180aa3
status               1 (success)
transactionHash      0x5ef08817a68b0577ed6aa3c379b9abc2ca3029cde374415a4c2053cb4f0c3a77
```

---

**5. Generate the attendee’s message hash**

```bash
cast call <contract_address> "getMessageHash(address)" <attendee_address>
```

**Sample Output:**

```
0xd2be1aca5fa2b7b293a2c881ef44dacea109d91b4f5ec8af41ae1174b9498113
```

---

**6. Organizer signs the message hash**

```bash
cast wallet sign --private-key <organizer_private_key> <message_hash>
```

**Sample Output:**

```
0xaecd208eaa7e5e04ddac5ea50a655070822df1ff6d0b0ef92c1eb426ed0e03944750fb81d2f416adfe619cf6d07620ee05961607efbd29bc5f52ea1fe30befd71b
```

---

**7. Attendee checks in with the signed message**

```bash
cast send <contract_address> \
--rpc-url http://127.0.0.1:8545 \
--private-key <attendee_private_key> \
"checkIn(bytes)" <signature>
```

**Sample Output:**

```
status               1 (success)
transactionHash      0xf70b26bf29a35043edf0629656e4be2afb6d96760f2bcccf96a32586c129cbd9
```

---

**8. Verify on-chain attendance**

```bash
cast call <contract_address> "hasAttended(address)" <attendee_address>
```

**Sample Output:**

```
0x0000000000000000000000000000000000000000000000000000000000000001
```

Value `1` confirms that the attendee has successfully checked in.

---

### Summary

This project demonstrates how to build an off-chain approval and on-chain verification flow using cryptographic signatures.
By leveraging `ecrecover`, it verifies authenticity without maintaining heavy on-chain lists.
This pattern can be extended to:

* Token-gated events
* NFT whitelist systems
* Ticket verification portals

If integrated with MetaMask or a frontend, the attendee would sign messages directly via their wallet, making the process fully decentralized and user-friendly.

---

End of the Project.
