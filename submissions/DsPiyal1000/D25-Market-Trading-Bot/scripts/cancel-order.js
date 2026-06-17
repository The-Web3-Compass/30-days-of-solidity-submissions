require("dotenv").config({ path: "./.env" });
const hre = require("hardhat");

/**
 * ============================================================================
 * Script 5: Cancel Spot Order
 * ============================================================================
 * 
 * Purpose:
 *   Cancels an existing spot order on the Injective exchange.
 *   Once cancelled, the funds are returned to the exchange subaccount.
 * 
 * Prerequisites:
 *   - Active order placed (run 4-place-order.js first)
 *   - CONTRACT_ADDRESS environment variable set
 *   - ORDER_HASH from the order placement
 *   - Same market ID as the original order
 * 
 * Configuration:
 *   MARKET_ID - Trading pair market ID (must match the order)
 *   ORDER_HASH - Hash of the order to cancel (from place-order output)
 * 
 * Important:
 *   - Only the contract owner can cancel orders
 *   - Order must exist and not be filled already
 *   - Funds are returned to exchange subaccount, not contract
 * 
 * Outputs:
 *   - Transaction hash
 *   - Cancellation confirmation
 *   - Timestamp of cancellation
 * 
 * Usage:
 *   CONTRACT_ADDRESS=0x... ORDER_HASH=0x... npm run cancel-order
 *   OR
 *   CONTRACT_ADDRESS=0x... ORDER_HASH=0x... npx hardhat run scripts/5-cancel-order.js --network injective_testnet
 * 
 * ============================================================================
 */

// ============================================================================
// CONFIGURATION - Modify these values as needed
// ============================================================================
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const MARKET_ID = "0x0611780ba69656949525013d947713300f56c37b6175e02f26bffa495c3208fe"; // INJ/USDT spot market
const ORDER_HASH = process.env.ORDER_HASH;// Get this from place-order script output

async function main() {
    console.log("=".repeat(60));
    console.log("CANCEL SPOT ORDER");
    console.log("=".repeat(60));

      if (!CONTRACT_ADDRESS) {
        throw new Error("Please set CONTRACT_ADDRESS in .env file (missing or not loaded)");
    }

      if (!ORDER_HASH) {
        throw new Error("Please set ORDER_HASH environment variable or update the script");
    }

    const [deployer] = await hre.ethers.getSigners();
    console.log("\n📍 Caller address:", deployer.address);
    console.log("📍 Contract address:", CONTRACT_ADDRESS);

    // Attach to the deployed contract instance
    const SimpleTradingBot = await hre.ethers.getContractFactory("SimpleTradingBot");
    const bot = SimpleTradingBot.attach(CONTRACT_ADDRESS);

    // Verify caller is the contract owner (only owner can cancel orders)
    const owner = await bot.owner();
    if (owner.toLowerCase() !== deployer.address.toLowerCase()) {
        throw new Error("Only contract owner can cancel orders. Owner: " + owner);
    }

    // Retrieve the contract's subaccount ID
    const subaccountId = await bot.getSubaccountId();
    console.log("🔑 Subaccount ID:", subaccountId);

    console.log("\n📋 Cancellation Details:");
    console.log("   Market ID:", MARKET_ID);
    console.log("   Order Hash:", ORDER_HASH);

    console.log("\n🗑️  Cancelling order...");

    // Call cancelSpotOrder on the contract
    // This will interact with the Injective Exchange Precompile to cancel the order
    const tx = await bot.cancelSpotOrder(MARKET_ID, ORDER_HASH);

    console.log("⏳ Transaction hash:", tx.hash);
    console.log("⏳ Waiting for confirmation...");

    const receipt = await tx.wait();
    console.log("✅ Transaction confirmed in block:", receipt.blockNumber);

    // Parse transaction logs to extract cancellation details from OrderCancelled event
    const orderCancelledEvent = receipt.logs.find(log => {
        try {
            const parsed = bot.interface.parseLog(log);
            return parsed && parsed.name === "OrderCancelled";
        } catch (e) {
            return false;
        }
    });

    if (orderCancelledEvent) {
        const parsed = bot.interface.parseLog(orderCancelledEvent);
        console.log("\n✅ Order cancelled successfully!");
        console.log("   Order Hash:", parsed.args.orderHash);
        console.log("   Market ID:", parsed.args.marketId);
        console.log("   Timestamp:", new Date(Number(parsed.args.timestamp) * 1000).toISOString());
    } else {
        console.log("\n⚠️  Warning: OrderCancelled event not found in logs");
    }

    console.log("\n" + "=".repeat(60));
    console.log("✅ ORDER CANCELLED SUCCESSFULLY");
    console.log("=".repeat(60));
    console.log("\n💡 Your funds are now available in the exchange subaccount");
    console.log("   You can place new orders or withdraw funds\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ Error:", error);
        process.exit(1);
    });