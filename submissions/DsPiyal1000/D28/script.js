const { ethers } = require("ethers");

// ABI for the withdrawEther function
const abi = [
  {
    "inputs": [],
    "name": "withdrawEther",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

// Create interface from ABI
const iface = new ethers.utils.Interface(abi);

// Encode function data
const data = iface.encodeFunctionData("withdrawEther");

// Log the transaction data
console.log("Transaction data for withdrawEther():");
console.log(data);

// Example usage:
// 1. Copy this data
// 2. Use it in a transaction to the FunTransfer contract address
// 3. Only the owner can successfully execute this transaction