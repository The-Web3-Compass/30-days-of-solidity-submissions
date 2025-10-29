require("dotenv").config({ path: "./.env" });
const hre = require("hardhat");

/**
 * ============================================================================
 * Script 3: Deposit to Exchange Subaccount
 * ============================================================================
 * 
 * Purpose:
 *   Deposits INJ from the contract's balance to its exchange subaccount.
 *   This is REQUIRED before placing any orders on the exchange.
 * 
 * Prerequisites:
 *   - Contract deployed and funded (run 1-deploy.js and 2-fund.js first)
 *   - CONTRACT_ADDRESS environment variable set
 *   - Contract has sufficient INJ balance
 * 
 * Configuration:
 *   DEPOSIT_AMOUNT - Amount to deposit (must be < contract balance)
 *   DENOM - Token denomination (default: "inj")
 * 
 * Important:
 *   The deposit amount MUST be less than the contract's balance to leave
 *   some INJ for gas fees in future transactions.
 * 
 * Outputs:
 *   - Transaction hash
 *   - Exchange balance before and after deposit
 *   - Contract balance after deposit
 * 
 * Usage:
 *   CONTRACT_ADDRESS=0x... npm run deposit
 *   OR
 *   CONTRACT_ADDRESS=0x... npx hardhat run scripts/3-deposit.js --network injective_testnet
 * 
 * Next Step:
 *   Run 4-place-order.js to create trading orders
 * 
 * ============================================================================
 */

// ============================================================================
// CONFIGURATION - Modify these values as needed
// ============================================================================
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const DEPOSIT_AMOUNT = "0.5"; // Amount in INJ to deposit (MUST BE LESS than funded amount)
const DENOM = "inj"; // Token denomination (inj for native INJ)
const USE_DEFAULT_SUBACCOUNT = true; // Use empty string for default subaccount

async function main() {
    console.log("=".repeat(60));
    console.log("DEPOSIT TO EXCHANGE");
    console.log("=".repeat(60));

  
     if (!CONTRACT_ADDRESS) {
        throw new Error("Please set CONTRACT_ADDRESS in .env file (missing or not loaded)");
    }


    const [deployer] = await hre.ethers.getSigners();
    console.log("\n📍 Caller address:", deployer.address);

    console.log("📍 Contract address:", CONTRACT_ADDRESS);

    // Attach to the deployed contract instance
    const SimpleTradingBot = await hre.ethers.getContractFactory("SimpleTradingBot");
    const bot = SimpleTradingBot.attach(CONTRACT_ADDRESS);

    // Verify caller is the contract owner (only owner can deposit)
    const owner = await bot.owner();
    if (owner.toLowerCase() !== deployer.address.toLowerCase()) {
        throw new Error("Only contract owner can deposit. Owner: " + owner);
    }

    // Check contract balance
    const contractBalance = await hre.ethers.provider.getBalance(CONTRACT_ADDRESS);
    console.log("💰 Contract balance:", hre.ethers.formatEther(contractBalance), "INJ");

    const depositAmountWei = hre.ethers.parseEther(DEPOSIT_AMOUNT);

    // Validate: deposit amount must be less than contract balance (to leave gas for future txs)
    if (depositAmountWei >= contractBalance) {
        throw new Error(
            `Deposit amount (${DEPOSIT_AMOUNT} INJ) must be less than contract balance (${hre.ethers.formatEther(contractBalance)} INJ)`
        );
    }

    // Retrieve the contract's subaccount ID for exchange operations
    const subaccountId = await bot.getSubaccountId();
    console.log("🔑 Subaccount ID:", subaccountId);

    // Check exchange balance before
    try {
        const [availableBefore, totalBefore] = await bot.getSubaccountBalance(DENOM);
        console.log("\n💰 Exchange balance before:");
        console.log("   Available:", hre.ethers.formatEther(availableBefore), DENOM);
        console.log("   Total:", hre.ethers.formatEther(totalBefore), DENOM);
    } catch (e) {
        console.log("\n💰 Exchange balance before: 0", DENOM, "(new subaccount)");
    }

    console.log("\n💸 Depositing", DEPOSIT_AMOUNT, DENOM, "to exchange...");

    // Call depositToExchange - this transfers INJ from contract to exchange subaccount
    // Note: No value is sent with this transaction as it uses the contract's existing balance
    const tx = await bot.depositToExchange(DENOM, depositAmountWei);

    console.log("⏳ Transaction hash:", tx.hash);
    console.log("⏳ Waiting for confirmation...");

    const receipt = await tx.wait();
    console.log("✅ Transaction confirmed in block:", receipt.blockNumber);

    // Check exchange balance after
    const [availableAfter, totalAfter] = await bot.getSubaccountBalance(DENOM);
    console.log("\n💰 Exchange balance after:");
    console.log("   Available:", hre.ethers.formatEther(availableAfter), DENOM);
    console.log("   Total:", hre.ethers.formatEther(totalAfter), DENOM);

    // Check contract balance after
    const contractBalanceAfter = await hre.ethers.provider.getBalance(CONTRACT_ADDRESS);
    console.log("\n💰 Contract balance after:", hre.ethers.formatEther(contractBalanceAfter), "INJ");

    console.log("\n" + "=".repeat(60));
    console.log("✅ DEPOSIT COMPLETE");
    console.log("=".repeat(60));
    console.log("\n💡 Next step: Run 4-place-order.js to create orders");
    console.log("   Make sure order value < " + DEPOSIT_AMOUNT + " INJ\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ Error:", error);
        process.exit(1);
    });