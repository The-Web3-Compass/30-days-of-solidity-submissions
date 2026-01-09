require("dotenv").config({ path: "./.env" });
const hre = require("hardhat");

/**
 * ============================================================================
 * Script 2: Fund the Trading Bot Contract
 * ============================================================================
 * 
 * Purpose:
 *   Sends native INJ tokens to the deployed SimpleTradingBot contract.
 *   These funds will be used for exchange deposits and trading operations.
 * 
 * Prerequisites:
 *   - Contract deployed (run 1-deploy.js first)
 *   - CONTRACT_ADDRESS environment variable set
 *   - Deployer wallet has sufficient INJ balance
 * 
 * Configuration:
 *   FUND_AMOUNT - Amount of INJ to send (default: "1.0")
 * 
 * Outputs:
 *   - Transaction hash
 *   - Contract balance before and after funding
 * 
 * Usage:
 *   CONTRACT_ADDRESS=0x... npm run fund
 *   OR
 *   CONTRACT_ADDRESS=0x... npx hardhat run scripts/2-fund.js --network injective_testnet
 * 
 * Next Step:
 *   Run 3-deposit.js to deposit funds to exchange subaccount
 * 
 * ============================================================================
 */

// ============================================================================
// CONFIGURATION - Modify these values as needed
// ============================================================================
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const FUND_AMOUNT = "1.0"; // Amount in INJ to fund the contract

async function main() {
    console.log("=".repeat(60));
    console.log("FUNDING TRADING BOT CONTRACT");
    console.log("=".repeat(60));

     if (!CONTRACT_ADDRESS) {
        throw new Error("Please set CONTRACT_ADDRESS in .env file (missing or not loaded)");
    }

    const [deployer] = await hre.ethers.getSigners();
    console.log("\n📍 Sender address:", deployer.address);
    
    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("💰 Sender balance:", hre.ethers.formatEther(balance), "INJ");

    console.log("\n📍 Contract address:", CONTRACT_ADDRESS);
    
    // Attach to the deployed contract instance
    const SimpleTradingBot = await hre.ethers.getContractFactory("SimpleTradingBot");
    const bot = SimpleTradingBot.attach(CONTRACT_ADDRESS);

    // Check contract balance before
    const balanceBefore = await hre.ethers.provider.getBalance(CONTRACT_ADDRESS);
    console.log("💰 Contract balance before:", hre.ethers.formatEther(balanceBefore), "INJ");

    // Convert amount to Wei and validate sender has sufficient balance
    const fundAmountWei = hre.ethers.parseEther(FUND_AMOUNT);
    if (fundAmountWei >= balance) {
        throw new Error("Insufficient balance. You need more than " + FUND_AMOUNT + " INJ");
    }

    console.log("\n💸 Sending", FUND_AMOUNT, "INJ to contract...");

    // Send INJ tokens to the contract address
    const tx = await deployer.sendTransaction({
        to: CONTRACT_ADDRESS,
        value: fundAmountWei
    });

    console.log("⏳ Transaction hash:", tx.hash);
    console.log("⏳ Waiting for confirmation...");
    
    await tx.wait();

    // Check contract balance after
    const balanceAfter = await hre.ethers.provider.getBalance(CONTRACT_ADDRESS);
    console.log("\n✅ Funding complete!");
    console.log("💰 Contract balance after:", hre.ethers.formatEther(balanceAfter), "INJ");
    console.log("📈 Funded amount:", hre.ethers.formatEther(balanceAfter - balanceBefore), "INJ");

    console.log("\n" + "=".repeat(60));
    console.log("✅ FUNDING COMPLETE");
    console.log("=".repeat(60));
    console.log("\n💡 Next step: Run 3-deposit.js to deposit to exchange");
    console.log("   Make sure deposit amount < " + FUND_AMOUNT + " INJ\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ Error:", error);
        process.exit(1);
    });