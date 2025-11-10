// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 💡 TipJar Contract
// This contract allows users to send ETH tips directly or in other currencies (USD, EUR, etc.)
// by converting the currency value into equivalent ETH based on manually defined conversion rates.
// It demonstrates how to:
//  - Handle ETH and wei
//  - Work safely with conversion math without decimals
//  - Manage access control with modifiers
//  - Withdraw ETH securely using .call()
//  - Expose read-only utility functions for data transparency

contract TipJar {
    // 👑 The address that deployed the contract becomes the owner (administrator)
    // Only the owner can add or update supported currencies or withdraw funds.
    address public owner;
    
    // 📊 Tracks the total ETH (in wei) received by the contract from all tippers.
    uint256 public totalTipsReceived;
    
    // 💱 Mapping of currency codes (like "USD") to ETH conversion rates (in wei).
    // Example: if 1 USD = 0.0005 ETH, store 5 * 10^14 (since 1 ETH = 10^18 wei).
    mapping(string => uint256) public conversionRates;

    // 🧾 Records how much ETH each address has tipped so far.
    mapping(address => uint256) public tipPerPerson;

    // 🌍 Stores the list of supported currency codes (for easy iteration & display).
    string[] public supportedCurrencies;

    // 💰 Keeps track of the total tip amounts per currency — useful for analytics.
    // Example: tipsPerCurrency["USD"] = 2000 means 2000 USD worth of tips were sent.
    mapping(string => uint256) public tipsPerCurrency;
    
    // 🧱 Constructor runs once at deployment.
    // Initializes contract owner and adds a few default currencies manually
    // (In a production dApp, you’d replace these with oracle-fed live rates, e.g., via Chainlink).
    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007 ETH
    }
    
    // 🔐 Modifier: restricts certain functions to only the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    // 🏦 Add or update a currency and its ETH conversion rate.
    // Rates are stored as wei equivalents for precise integer math.
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");
        bool currencyExists = false;

        // ⚙️ Loop through the supported currency list to check if it already exists.
        // Note: Solidity cannot compare strings directly, so we hash them using keccak256 for safe comparison.
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                currencyExists = true;
                break;
            }
        }

        // If the currency doesn’t exist yet, add it to the list.
        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }

        // ✅ Set or update the conversion rate (in wei).
        conversionRates[_currencyCode] = _rateToEth;
    }
    
    // 🔄 Convert an amount in another currency to ETH (in wei).
    // Returns the equivalent ETH amount based on stored conversion rate.
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;

        // ⚠️ Reminder:
        // Solidity doesn’t support decimals. Keep all values in wei.
        // To show human-readable ETH in your frontend, divide by 10^18 off-chain.
    }
    
    // 💸 Function to send a direct ETH tip.
    // The `payable` keyword allows this function to receive ETH.
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");

        // Record how much this tipper has sent.
        tipPerPerson[msg.sender] += msg.value;

        // Update total received ETH.
        totalTipsReceived += msg.value;

        // Track ETH tips separately under “ETH”.
        tipsPerCurrency["ETH"] += msg.value;
    }
    
    // 🌐 Send a tip in another currency (e.g., USD, EUR, etc.)
    // The user specifies the currency and amount, then sends the ETH equivalent.
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");

        // Convert the foreign currency to ETH (in wei)
        uint256 ethAmount = convertToEth(_currencyCode, _amount);

        // Verify that the actual ETH sent (msg.value) matches the expected amount.
        // This prevents underpaying or overpaying by mistake.
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");

        // Record tip data
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    // 🏧 Owner can withdraw all collected tips (in ETH).
    // Uses `.call{value:...}` for safe and flexible transfers.
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");

        // 🚨 `.call` is preferred over `.transfer` or `.send` for flexibility and safety.
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");

        // Reset totalTipsReceived (bookkeeping only; doesn’t affect actual balance post-transfer).
        totalTipsReceived = 0;
    }
  
    // 👥 Allows owner to hand over ownership to a new address.
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    // 🔍 View functions (read-only, gas-free when called off-chain)
    // Useful for displaying data in UI or analytics dashboards.

    // List all supported currencies.
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }
    
    // Check total ETH currently stored in the contract.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // Check how much a specific user has tipped (in wei).
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }
    
    // See how much total tip (in foreign currency) was sent under a specific currency.
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    // Get the ETH conversion rate for a currency (in wei).
    // Example: getConversionRate("USD") → 5 * 10^14 means 1 USD = 0.0005 ETH
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}
