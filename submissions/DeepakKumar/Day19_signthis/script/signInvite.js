// Node.js + ethers
const { ethers } = require("ethers");

// Example: using a private key (IN REALITY keep it safe, use env var / HSM)
const ORGANIZER_PRIVATE_KEY = process.env.ORGANIZER_PRIVATE_KEY; // set in env
const RPC = "http://localhost:8545"; // or mainnet/testnet provider if real

async function signInvite(contractAddress, eventName, attendeeAddress) {
  const provider = new ethers.providers.JsonRpcProvider(RPC);
  const wallet = new ethers.Wallet(ORGANIZER_PRIVATE_KEY, provider);

  // Build message the same way the contract does:
  const messageHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["address", "string", "address"],
      [contractAddress, eventName, attendeeAddress]
    )
  );

  // Note: contract uses abi.encodePacked, so above uses exact types order to be safe.
  // Now compute Ethereum prefixed hash and sign:
  const arrayifiedHash = ethers.utils.arrayify(messageHash);
  const signature = await wallet.signMessage(arrayifiedHash); // ethers will prefix automatically

  return signature; // send to the attendee
}

// Example usage
(async () => {
  const signature = await signInvite(
    "0xYourDeployedContractAddress",
    "Web3 Summit",
    "0xAttendeeAddress"
  );
  console.log("Signature:", signature);
})();
