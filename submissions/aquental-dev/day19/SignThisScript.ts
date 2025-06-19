const Web3 = require("web3");
const web3 = new Web3(); // Remix provides web3
const message =
  '{"attendee":"0xc2572E65d61aFa5DD6BcFAC57305Bb59EBD9A54E","event":"30 days of Solidity"}';
const privateKey =
  "63a2a7b2854b99601bd026daefe9968b963a3fe5a76882a6dc8ed76430b76677"; // Replace with organizer’s private key from Remix
const messageHash = web3.utils.keccak256(
  "\x19Ethereum Signed Message:\n" + message.length + message
);
const signature = web3.eth.accounts.sign(messageHash, privateKey);
console.log("Message Hash:", messageHash);
console.log("Signature:", signature.signature);
