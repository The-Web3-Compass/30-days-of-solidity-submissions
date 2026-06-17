const hre = require("hardhat");

/**
 * ============================================================================
 * Script 1: Deploy SimpleTradingBot Contract
 * ============================================================================
 * 
 * Purpose:
 *   Deploys the SimpleTradingBot smart contract to Injective testnet.
 *   The contract is initialized with a subaccount nonce for exchange operations.
 * 
 * Prerequisites:
 *   - Hardhat configured with Injective testnet RPC
 *   - Private key with testnet INJ tokens for gas
 *   - SimpleTradingBot.sol compiled
 * 
 * Outputs:
 *   - Contract address (save this to .env as CONTRACT_ADDRESS)
 *   - Owner address
 *   - Subaccount ID
 * 
 * Usage:
 *   npm run deploy
 *   OR
 *   npx hardhat run scripts/1-deploy.js --network injective_testnet
 * 
 * ============================================================================
 */

async function main() {
    console.log("=".repeat(60));
    console.log("DEPLOYING SIMPLE TRADING BOT");
    console.log("=".repeat(60));

    const [deployer] = await hre.ethers.getSigners();
    console.log("\n📍 Deployer address:", deployer.address);
    
    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("💰 Deployer balance:", hre.ethers.formatEther(balance), "INJ");

    // Subaccount nonce (1 for first subaccount, as per Injective convention)
    // This nonce is used to derive the subaccount ID for exchange operations
    const SUBACCOUNT_NONCE = 1;
    
    console.log("\n🚀 Deploying SimpleTradingBot...");
    console.log("   Subaccount Nonce:", SUBACCOUNT_NONCE);

    // Get contract factory and deploy with subaccount nonce
    const SimpleTradingBot = await hre.ethers.getContractFactory("SimpleTradingBot");
    const bot = await SimpleTradingBot.deploy(SUBACCOUNT_NONCE);
    
    // Wait for deployment transaction to be mined
    await bot.waitForDeployment();
    const contractAddress = await bot.getAddress();

    console.log("\n✅ SimpleTradingBot deployed!");
    console.log("📍 Contract Address:", contractAddress);

    // Retrieve contract information for verification
    const [addr, owner, isPaused, subaccountId] = await bot.getContractInfo();
    
    console.log("\n📋 Contract Information:");
    console.log("   Owner:", owner);
    console.log("   Trading Paused:", isPaused);
    console.log("   Subaccount ID:", subaccountId);

    console.log("\n" + "=".repeat(60));
    console.log("✅ DEPLOYMENT COMPLETE");
    console.log("=".repeat(60));
    console.log("\n💾 Save this contract address for next steps:");
    console.log("   CONTRACT_ADDRESS=" + contractAddress);
    console.log("\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ Error:", error);
        process.exit(1);
    });