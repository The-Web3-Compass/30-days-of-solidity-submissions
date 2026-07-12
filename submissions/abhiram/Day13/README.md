# Day 13: PreOrder Tokens - Token Pre-Sale Contract

A comprehensive Solidity smart contract that enables token pre-sales, allowing users to purchase tokens with Ether at a fixed rate. This contract demonstrates fundamental concepts of token economics, rate calculations, and sales management.

## 📋 Contract Overview

The `PreorderTokens` contract is a complete token pre-sale system that:
- Allows users to buy tokens by sending Ether
- Manages token pricing and conversion rates
- Tracks sales statistics and buyer history
- Provides owner controls for managing the sale

## 🎯 Key Concepts Covered

### 1. **Token Economics**
Token economics (tokenomics) involves the supply, distribution, and pricing of digital tokens:
- **Supply Management**: Total supply is set at deployment
- **Price Discovery**: Fixed price per token (can be updated by owner)
- **Distribution**: Tokens are sold through the contract to buyers
- **Scarcity**: Limited tokens available for sale

### 2. **Rate Calculations**
Converting between Ether and tokens requires precise mathematical operations:

```solidity
// Formula: tokens = (etherAmount * 10^18) / tokenPrice
function calculateTokenAmount(uint256 etherAmount) public view returns (uint256) {
    return (etherAmount * 10**decimals) / tokenPrice;
}

// Inverse: ether = (tokenAmount * tokenPrice) / 10^18
function calculateEtherCost(uint256 tokenAmount) public view returns (uint256) {
    return (tokenAmount * tokenPrice) / 10**decimals;
}
```

**Why these formulas?**
- Tokens have 18 decimals (1 token = 1 × 10^18 smallest units)
- Ether also has 18 decimals (1 ETH = 1 × 10^18 wei)
- Calculations maintain precision by working with the smallest units

### 3. **Sales Management**
Managing the entire lifecycle of a token pre-sale:
- **Sale Activation**: Toggle sale on/off
- **Purchase Limits**: Set minimum and maximum purchase amounts
- **Progress Tracking**: Monitor tokens sold and Ether raised
- **Withdrawal**: Owner can withdraw funds after sale

## 🚀 Features

### Core Functionality

1. **Token Purchase**
   - Send Ether to buy tokens automatically
   - Calculates token amount based on current price
   - Enforces purchase limits

2. **Price Management**
   - Owner can update token price
   - Real-time rate calculations
   - Price history through events

3. **Sale Controls**
   - Start/stop sale at any time
   - Set purchase limits (min/max)
   - Track individual purchases

4. **Statistics & Reporting**
   - Total tokens sold
   - Total Ether raised
   - Sale progress percentage
   - Individual buyer history

## 📊 Contract Architecture

```
PreorderTokens
├── Token Properties
│   ├── name, symbol, decimals
│   ├── totalSupply
│   └── balances mapping
│
├── Sale Parameters
│   ├── tokenPrice
│   ├── tokensAvailable
│   ├── tokensSold
│   └── saleActive flag
│
├── Purchase Functions
│   ├── buyTokens() - Main purchase function
│   ├── calculateTokenAmount() - Convert ETH to tokens
│   └── calculateEtherCost() - Convert tokens to ETH
│
├── Owner Functions
│   ├── setTokenPrice() - Update price
│   ├── setPurchaseLimits() - Set min/max
│   ├── toggleSale() - Enable/disable sale
│   ├── withdrawEther() - Withdraw raised funds
│   └── withdrawUnsoldTokens() - Reclaim unsold tokens
│
└── View Functions
    ├── getSaleInfo() - Get sale statistics
    ├── getPurchaseLimits() - Get current limits
    ├── getTokensPerEther() - Get exchange rate
    └── getSaleProgress() - Get progress percentage
```

## 💻 Usage Examples

### Deploying the Contract

```solidity
// Deploy with:
// - 1,000,000 total supply
// - 0.001 ETH per token price
// - 500,000 tokens for sale
PreorderTokens presale = new PreorderTokens(
    1000000,              // Initial supply (1M tokens)
    1000000000000000,     // Token price (0.001 ETH in wei)
    500000                // Tokens for sale (500K tokens)
);
```

### Buying Tokens

```javascript
// Example 1: Send 1 ETH to buy tokens
await presale.buyTokens({ value: ethers.parseEther("1.0") });

// Example 2: Direct send (using receive function)
await signer.sendTransaction({
    to: presaleAddress,
    value: ethers.parseEther("0.5")
});

// Check balance
const balance = await presale.balanceOf(buyerAddress);
```

### Rate Calculations Example

If token price is set to `0.001 ETH` (1,000,000,000,000,000 wei):

```
1 ETH = 1,000 tokens
0.5 ETH = 500 tokens
0.001 ETH = 1 token

Calculation:
tokens = (1 ETH * 10^18) / (0.001 ETH in wei)
       = (1,000,000,000,000,000,000) / (1,000,000,000,000,000)
       = 1,000 tokens
```

### Owner Operations

```javascript
// Update token price to 0.002 ETH
await presale.setTokenPrice(ethers.parseEther("0.002"));

// Set purchase limits
await presale.setPurchaseLimits(
    ethers.parseEther("0.01"),  // Min: 0.01 ETH
    ethers.parseEther("5")      // Max: 5 ETH
);

// End sale
await presale.endSale();

// Withdraw raised Ether
await presale.withdrawEther();

// Withdraw unsold tokens
await presale.withdrawUnsoldTokens();
```

### Getting Sale Information

```javascript
// Get sale statistics
const [price, available, sold, raised, active] = await presale.getSaleInfo();

console.log(`Token Price: ${ethers.formatEther(price)} ETH`);
console.log(`Tokens Available: ${ethers.formatUnits(available, 18)}`);
console.log(`Tokens Sold: ${ethers.formatUnits(sold, 18)}`);
console.log(`Ether Raised: ${ethers.formatEther(raised)} ETH`);
console.log(`Sale Active: ${active}`);

// Get exchange rate
const tokensPerEth = await presale.getTokensPerEther();
console.log(`Rate: 1 ETH = ${ethers.formatUnits(tokensPerEth, 18)} tokens`);

// Get sale progress
const progress = await presale.getSaleProgress();
console.log(`Progress: ${progress}%`);
```

## 🔐 Security Considerations

1. **Reentrancy Protection**: Uses checks-effects-interactions pattern
2. **Integer Overflow**: Uses Solidity 0.8.x with built-in overflow checks
3. **Access Control**: Owner-only functions protected with modifiers
4. **Input Validation**: All inputs are validated before processing
5. **Safe Math**: All calculations use safe arithmetic operations

## 📈 Token Economics Explained

### Why Fixed Price?

This contract uses a **fixed-price model** where:
- Price is set at deployment and can be updated by owner
- Simple and predictable for buyers
- Good for pre-sales and initial offerings

### Alternative Models

1. **Bonding Curve**: Price increases as more tokens are sold
2. **Dutch Auction**: Price decreases over time
3. **Dynamic Pricing**: Price based on demand/supply

### Supply Management

```
Total Supply: 1,000,000 tokens
├── For Sale: 500,000 tokens (50%)
└── Reserved: 500,000 tokens (50%)
    ├── Team allocation
    ├── Development fund
    └── Liquidity reserves
```

## 📝 Events

The contract emits events for transparency and off-chain tracking:

```solidity
event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount, uint256 timestamp);
event SaleStatusChanged(bool active, uint256 timestamp);
event PriceUpdated(uint256 oldPrice, uint256 newPrice);
event TokensWithdrawn(address indexed owner, uint256 amount);
event EtherWithdrawn(address indexed owner, uint256 amount);
```

## 🧪 Testing Scenarios

### Test Cases to Cover

1. **Purchase Tests**
   - ✅ Buy tokens with valid amount
   - ✅ Reject purchases below minimum
   - ✅ Reject purchases above maximum
   - ✅ Handle insufficient tokens available
   - ✅ Verify correct token calculation

2. **Rate Calculation Tests**
   - ✅ Verify ETH to token conversion
   - ✅ Verify token to ETH conversion
   - ✅ Test with different price points
   - ✅ Test precision with small amounts

3. **Owner Function Tests**
   - ✅ Only owner can change price
   - ✅ Only owner can toggle sale
   - ✅ Only owner can withdraw funds
   - ✅ Non-owner calls revert

4. **Edge Cases**
   - ✅ Purchase when sale is inactive
   - ✅ Purchase all remaining tokens
   - ✅ Withdraw with zero balance
   - ✅ Multiple purchases from same address

## 🎓 Learning Outcomes

After understanding this contract, you will know:

1. **How to implement token sales** with Ether
2. **How to calculate conversion rates** between cryptocurrencies
3. **How to manage token supply** and distribution
4. **How to implement owner controls** for contract management
5. **How to track and report sales metrics**
6. **How to handle Ether transfers** safely
7. **How to design a complete sales lifecycle**

## 🔄 Workflow Diagram

```
User Sends Ether
    ↓
Validate Amount (min/max)
    ↓
Check Sale Active
    ↓
Calculate Token Amount
    ↓
Check Token Availability
    ↓
Update State (available, sold, raised)
    ↓
Transfer Tokens to User
    ↓
Emit TokensPurchased Event
    ↓
Complete Purchase ✓
```

## 🛠️ Deployment Checklist

Before deploying to mainnet:

- [ ] Set appropriate initial supply
- [ ] Calculate correct token price in wei
- [ ] Determine tokens to sell vs. reserve
- [ ] Set reasonable purchase limits
- [ ] Test all functions on testnet
- [ ] Verify math calculations
- [ ] Audit contract code
- [ ] Prepare withdrawal plan
- [ ] Set up event monitoring
- [ ] Document price and supply decisions

## 📚 Additional Resources

### Related Concepts
- **ERC-20 Standard**: Full token implementation
- **Crowdsale Patterns**: Various ICO/presale models
- **Vesting Schedules**: Time-locked token release
- **Multi-sig Wallets**: Secure fund management

### Further Reading
- [Ethereum Token Standards](https://ethereum.org/en/developers/docs/standards/tokens/)
- [Token Economics 101](https://ethereum.org/en/developers/docs/tokens/)
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)

## 🤝 Contributing

This is a learning project. Feel free to:
- Add new features (e.g., whitelisting, referral system)
- Improve gas efficiency
- Add more comprehensive tests
- Enhance documentation

## ⚠️ Disclaimer

This contract is for educational purposes. Before using in production:
- Conduct thorough security audits
- Add comprehensive testing
- Consider additional features (pause, emergency stop)
- Implement proper access control (multi-sig)
- Review and comply with legal regulations

## 📄 License

MIT License - Feel free to use for learning and development.

---

**Day 13 of 30 Days of Solidity** 🚀

Built with ❤️ for learning Solidity and blockchain development.
