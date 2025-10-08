# Day 8: Multi-Currency TipJar 🌍💰

A sophisticated smart contract that functions as a global digital tip jar, accepting tips in ETH and simulating multiple foreign currencies (INR, USD, EUR).

## 🎯 Features

### Core Functionality
- **Direct ETH Tips**: Accept tips directly in Ether with optional messages
- **Multi-Currency Support**: Simulate tips in INR, USD and EUR
- **Currency Conversion**: Automatic conversion between foreign currencies and ETH
- **Contribution Tracking**: Track individual contributions per tipper
- **Message System**: Allow tippers to leave messages with their tips

### Advanced Features
- **Exchange Rate Management**: Owner can update currency exchange rates
- **Multiple Withdrawal Options**: Withdraw all tips or specific amounts
- **Statistics Dashboard**: View comprehensive tip jar statistics
- **Event Logging**: All tips and withdrawals are logged via events
- **Tipper History**: Query all tips from a specific address

## 📋 Contract Details

### Supported Currencies
```solidity
enum Currency { ETH, INR, USD, EUR }
```

### Key Data Structures

**Tip Struct:**
```solidity
struct Tip {
    address tipper;        // Address of the person who tipped
    uint256 amount;        // Amount in Wei (ETH) or smallest unit
    Currency currency;     // Currency used
    uint256 timestamp;     // When the tip was made
    string message;        // Optional message
}
```

**Tracking Variables:**
- `totalTipsReceived`: Total tips in Wei equivalent
- `contributionsByTipper`: Map of tipper → total contributed
- `tipsByCurrency`: Map of currency → total amount in that currency

## 🔧 Main Functions

### For Tippers

#### `tipInETH(string memory _message)`
Send a tip directly in ETH.
```solidity
tipJar.tipInETH{value: 0.1 ether}("Thanks for the great content!");
```

#### `tipInForeignCurrency(uint256 _amount, Currency _currency, string memory _message)`
Simulate a tip in foreign currency.
```solidity
// Tip ₹100 (10000 paise)
uint256 ethNeeded = tipJar.convertToETH(10000, Currency.INR);
tipJar.tipInForeignCurrency{value: ethNeeded}(10000, Currency.INR, "Great work!");
```

#### View Functions
- `convertToETH(uint256 _amount, Currency _currency)`: Calculate ETH equivalent
- `convertFromETH(uint256 _ethAmount, Currency _currency)`: Calculate foreign currency equivalent
- `contributionsByTipper(address)`: Check your total contributions
- `getTipsByTipper(address _tipper)`: Get all tip indices from a specific address

### For Owner

#### `withdrawTips()`
Withdraw all accumulated tips.

#### `withdrawAmount(uint256 _amount)`
Withdraw a specific amount.

#### `updateExchangeRate(Currency _currency, uint256 _newRate)`
Update the exchange rate for a currency (e.g., after market changes).

### General View Functions

- `getBalance()`: Get current contract balance
- `getTipCount()`: Get total number of tips
- `getTip(uint256 _index)`: Get details of a specific tip
- `getStats()`: Get comprehensive statistics

## 💡 Usage Examples

### Example 1: Tip in ETH
```solidity
// Send 0.5 ETH tip with a message
tipJar.tipInETH{value: 0.5 ether}("Love your work!");
```

### Example 2: Tip in USD
```solidity
// Tip ₹500 (50000 cents)
uint256 amount = 50000;
Currency currency = Currency.INR;

// Calculate required ETH
uint256 ethRequired = tipJar.convertToETH(amount, currency);

// Send tip
tipJar.tipInForeignCurrency{value: ethRequired}(
    amount,
    currency,
    "Keep creating!"
);
```

### Example 3: Check Your Contributions
```solidity
// Get total contributions
uint256 myTotal = tipJar.contributionsByTipper(msg.sender);

// Get all your tip indices
uint256[] memory myTips = tipJar.getTipsByTipper(msg.sender);
```

### Example 4: Owner Withdrawal
```solidity
// Withdraw all tips
tipJar.withdrawTips();

// Or withdraw specific amount (0.5 ETH)
tipJar.withdrawAmount(0.5 ether);
```

### Example 5: Update Exchange Rates
```solidity
// Update USD rate to reflect ₹300000 per ETH
tipJar.updateExchangeRate(Currency.INR, 300000 * 100);
```

## 🔒 Security Features

1. **Owner-only Functions**: Withdrawal and rate updates restricted to owner
2. **Input Validation**: All functions validate inputs
3. **Refund Mechanism**: Automatically refunds excess ETH in foreign currency tips
4. **No Zero Amounts**: Prevents zero-value tips
5. **Balance Checks**: Ensures sufficient balance before withdrawals

## 📊 Exchange Rate System

The contract uses simulated exchange rates (stored in `exchangeRates` mapping):
- **INR** 200000 * 100 paise per ETH (1 ETH ≈ ₹2,00,000)
- **USD**: 2500 * 100 cents per ETH (1 ETH ≈ $2,500)
- **EUR**: 2300 * 100 cents per ETH (1 ETH ≈ €2,300)

**Note**: In production, use Chainlink price feeds or similar oracles for real-time rates.

## 🎓 Learning Objectives

This contract demonstrates:
1. **`payable` Functions**: Accepting ETH with `msg.value`
2. **Currency Conversion**: Mathematical conversion between currencies
3. **Data Structures**: Using structs, enums, and mappings effectively
4. **Event Emission**: Logging important actions
5. **Access Control**: Owner-only functions using modifiers
6. **Array Operations**: Filtering and searching through arrays
7. **ETH Transfers**: Using `transfer()` for withdrawals and refunds
8. **`receive()` Function**: Handling direct ETH transfers

## 🚀 Deployment

```solidity
// Deploy the contract
TipJar tipJar = new TipJar();

// The deployer becomes the owner
// Exchange rates are automatically initialized
```

## 📝 Events

```solidity
event TipReceived(
    address indexed tipper,
    uint256 amount,
    Currency currency,
    uint256 ethEquivalent,
    string message,
    uint256 timestamp
);

event ExchangeRateUpdated(Currency currency, uint256 newRate);
event Withdrawal(address indexed owner, uint256 amount);
```

## 🌟 Real-World Applications

- Content creator tip jars
- International donation platforms
- Multi-currency payment processors
- Cross-border remittance systems
- Freelancer payment systems

## 🔮 Potential Enhancements

1. **Oracle Integration**: Use Chainlink for real exchange rates
2. **Token Support**: Accept ERC20 tokens
3. **Tip Goals**: Set funding goals with progress tracking
4. **Tipper Rewards**: NFTs or badges for top contributors
5. **Recurring Tips**: Subscription-based tipping
6. **Multi-recipient**: Split tips among multiple beneficiaries
7. **Tax Reporting**: Export contribution data for tax purposes

---

**Built with ❤️ for the 30 Days of Solidity Challenge**