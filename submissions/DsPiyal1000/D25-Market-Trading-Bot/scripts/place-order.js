require("dotenv").config({ path: "./.env" });
const hre = require("hardhat");

/**
 * ============================================================================
 * Script 4: Place Spot Limit Order
 * ============================================================================
 * 
 * Purpose:
 *   Creates a spot limit order on the Injective exchange.
 *   This can be either a buy or sell order based on configuration.
 * 
 * Prerequisites:
 *   - Contract deployed, funded, and deposited to exchange
 *   - CONTRACT_ADDRESS environment variable set
 *   - Sufficient balance in exchange subaccount
 *   - Valid market ID for the trading pair
 * 
 * Configuration:
 *   MARKET_ID - Trading pair market ID (get from Injective Explorer)
 *   ORDER_PRICE - Limit order price
 *   ORDER_QUANTITY - Order size
 *   IS_BUY - true for buy order, false for sell order
 * 
 * Important:
 *   - For SELL orders: Need INJ in subaccount
 *   - For BUY orders: Need USDT (or quote token) in subaccount
 *   - Total order value must be less than available balance
 * 
 * Outputs:
 *   - Transaction hash
 *   - Order hash (save this for cancellation)
 *   - Order details
 * 
 * Usage:
 *   CONTRACT_ADDRESS=0x... npm run place-order
 *   OR
 *   CONTRACT_ADDRESS=0x... npx hardhat run scripts/4-place-order.js --network injective_testnet
 * 
 * Next Step:
 *   Run 5-cancel-order.js to cancel the order (optional)
 * 
 * ============================================================================
 */

// ============================================================================
// CONFIGURATION - Modify these values as needed
// ============================================================================
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const MARKET_ID = "0x0611780ba69656949525013d947713300f56c37b6175e02f26bffa495c3208fe"; // INJ/USDT spot market

// Order parameters (MUST ensure total value < deposited amount)
const ORDER_PRICE = "25.5"; // Price in USDT per INJ
const ORDER_QUANTITY = "0.01"; // Quantity in INJ (small amount for testing)
const IS_BUY = false; // true = buy order, false = sell order

async function main() {
    console.log("=".repeat(60));
    console.log("PLACE SPOT ORDER");
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

    // Verify caller is the contract owner (only owner can place orders)
    const owner = await bot.owner();
    if (owner.toLowerCase() !== deployer.address.toLowerCase()) {
        throw new Error("Only contract owner can place orders. Owner: " + owner);
    }

    // Check if trading is paused (safety check)
    const isPaused = await bot.tradingPaused();
    if (isPaused) {
        throw new Error("Trading is paused. Unpause first.");
    }

    // Retrieve the contract's subaccount ID
    const subaccountId = await bot.getSubaccountId();
    console.log("🔑 Subaccount ID:", subaccountId);

    // Determine which token balance to check based on order type
    // Buy orders need USDT (quote token), Sell orders need INJ (base token)
    const denom = IS_BUY ? "peggy0x87aB3B4C8661e07D6372361211B96ed4Dc36B1B5" : "inj"; // USDT for buy, INJ for sell
    try {
        const [available, total] = await bot.getSubaccountBalance(denom);
        console.log(`\n💰 Exchange balance (${IS_BUY ? 'USDT' : 'INJ'}):`);
        console.log("   Available:", hre.ethers.formatEther(available));
        console.log("   Total:", hre.ethers.formatEther(total));

        // Validate: for sell orders, ensure we have enough INJ
        if (!IS_BUY) {
            const orderQtyWei = hre.ethers.parseEther(ORDER_QUANTITY);
            if (orderQtyWei > available) {
                throw new Error(
                    `Insufficient balance. Need ${ORDER_QUANTITY} INJ, have ${hre.ethers.formatEther(available)} INJ`
                );
            }
        }
    } catch (e) {
        console.log("\n⚠️  Warning: Could not fetch balance -", e.message);
    }

    console.log("\n📋 Order Details:");
    console.log("   Market ID:", MARKET_ID);
    console.log("   Type:", IS_BUY ? "BUY" : "SELL");
    console.log("   Price:", ORDER_PRICE, "USDT");
    console.log("   Quantity:", ORDER_QUANTITY, "INJ");
    console.log("   Total Value:", (parseFloat(ORDER_PRICE) * parseFloat(ORDER_QUANTITY)).toFixed(2), "USDT");

    // Convert price and quantity to Wei (18 decimals)
    const priceWei = hre.ethers.parseEther(ORDER_PRICE);
    const quantityWei = hre.ethers.parseEther(ORDER_QUANTITY);

    console.log("\n📤 Placing spot limit order...");

    // Call placeSpotLimitOrder on the contract
    // This will interact with the Injective Exchange Precompile
    const tx = await bot.placeSpotLimitOrder(
        MARKET_ID,
        priceWei,
        quantityWei,
        IS_BUY
    );

    console.log("⏳ Transaction hash:", tx.hash);
    console.log("⏳ Waiting for confirmation...");

    const receipt = await tx.wait();
    console.log("✅ Transaction confirmed in block:", receipt.blockNumber);

    // Parse transaction logs to extract the order hash from SpotOrderPlaced event
    const orderPlacedEvent = receipt.logs.find(log => {
        try {
            const parsed = bot.interface.parseLog(log);
            return parsed && parsed.name === "SpotOrderPlaced";
        } catch (e) {
            return false;
        }
    });

    if (orderPlacedEvent) {
        const parsed = bot.interface.parseLog(orderPlacedEvent);
        console.log("\n📝 Order Hash:", parsed.args.orderHash);
    }

    console.log("\n" + "=".repeat(60));
    console.log("✅ ORDER PLACED SUCCESSFULLY");
    console.log("=".repeat(60));
    console.log("\n💡 Next step: Run 5-cancel-order.js to cancel the order");
    console.log("   Use the order hash printed above\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ Error:", error);
        process.exit(1);
    });