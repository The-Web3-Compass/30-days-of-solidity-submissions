//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title TipJar
 * @dev A multi-currency digital tip jar that accepts ETH and simulates foreign currency tips
 * @notice This contract demonstrates payable functions, currency conversion, and contribution tracking
 */
contract TipJar {
    // Owner of the tip jar (recipient of tips)
    address public owner;
    
    // Total tips received in Wei
    uint256 public totalTipsReceived;
    
    // Enum for supported currencies
    enum Currency { ETH, INR, USD, EUR }
    
    // Struct to track individual tips
    struct Tip {
        address tipper;
        uint256 amount;        // Amount in Wei (for ETH)
        Currency currency;
        uint256 timestamp;
        string message;
    }
    
    // Array of all tips
    Tip[] public tips;
    
    // Mapping to track total contributions per tipper (in Wei equivalent)
    mapping(address => uint256) public contributionsByTipper;
    
    // Mapping to track tips by currency
    mapping(Currency => uint256) public tipsByCurrency;
    
    // Simulated exchange rates (rates are per 1 ETH in smallest unit)
    // In production, you'd use an oracle like Chainlink
    mapping(Currency => uint256) public exchangeRates;
    
    // Events
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
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Sets the contract deployer as owner and initializes exchange rates
    constructor() {
        owner = msg.sender;
        
        // Initialize simulated exchange rates (example rates)
        exchangeRates[Currency.ETH] = 1 ether;           // 1 ETH = 1 ETH
        exchangeRates[Currency.INR] = 200000 * 100;      // 1 ETH ≈ ₹200,000 (in paise)
        exchangeRates[Currency.USD] = 2500 * 100;        // 1 ETH ≈ $2,500 (in cents)
        exchangeRates[Currency.EUR] = 2300 * 100;        // 1 ETH ≈ €2,300 (in cents)
    }
    
    // Send a tip in ETH with an optional message
    function tipInETH(string memory _message) public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        // Record the tip
        tips.push(Tip({
            tipper: msg.sender,
            amount: msg.value,
            currency: Currency.ETH,
            timestamp: block.timestamp,
            message: _message
        }));
        
        // Update tracking variables
        totalTipsReceived += msg.value;
        contributionsByTipper[msg.sender] += msg.value;
        tipsByCurrency[Currency.ETH] += msg.value;
        
        emit TipReceived(
            msg.sender,
            msg.value,
            Currency.ETH,
            msg.value,
            _message,
            block.timestamp
        );
    }
    
    /**
     * @dev Simulate a tip in foreign currency (INR, USD, EUR)
     * @param _amount Amount in the smallest unit of the currency
     * @param _currency The currency being used
     * @param _message Optional message from the tipper
     */
    function tipInForeignCurrency(
        uint256 _amount,
        Currency _currency,
        string memory _message
    ) public payable {
        require(_currency != Currency.ETH, "Use tipInETH() for ETH tips");
        require(_amount > 0, "Tip amount must be greater than 0");
        
        // Calculate ETH equivalent
        uint256 ethEquivalent = convertToETH(_amount, _currency);
        require(msg.value >= ethEquivalent, "Insufficient ETH sent for conversion");
        
        // Record the tip
        tips.push(Tip({
            tipper: msg.sender,
            amount: _amount,
            currency: _currency,
            timestamp: block.timestamp,
            message: _message
        }));
        
        // Update tracking variables
        totalTipsReceived += ethEquivalent;
        contributionsByTipper[msg.sender] += ethEquivalent;
        tipsByCurrency[_currency] += _amount;
        
        emit TipReceived(
            msg.sender,
            _amount,
            _currency,
            ethEquivalent,
            _message,
            block.timestamp
        );
        
        // Refund excess ETH if any
        if (msg.value > ethEquivalent) {
            payable(msg.sender).transfer(msg.value - ethEquivalent);
        }
    }
    
    /**
     * @dev Convert foreign currency amount to ETH equivalent
     * @param _amount Amount in foreign currency
     * @param _currency The currency to convert from
     * @return ETH equivalent in Wei
     */
    function convertToETH(uint256 _amount, Currency _currency) public view returns (uint256) {
        require(_currency != Currency.ETH, "Cannot convert ETH to ETH");
        require(exchangeRates[_currency] > 0, "Exchange rate not set");
        
        return (_amount * 1 ether) / exchangeRates[_currency];
    }
    
    /**
     * @dev Convert ETH amount to foreign currency equivalent
     * @param _ethAmount Amount in Wei
     * @param _currency The currency to convert to
     * @return Foreign currency equivalent
     */
    function convertFromETH(uint256 _ethAmount, Currency _currency) public view returns (uint256) {
        require(_currency != Currency.ETH, "Cannot convert ETH to ETH");
        require(exchangeRates[_currency] > 0, "Exchange rate not set");
        
        return (_ethAmount * exchangeRates[_currency]) / 1 ether;
    }
    
    /**
     * @dev Update exchange rate for a currency (owner only)
     * @param _currency Currency to update
     * @param _newRate New exchange rate
     */
    function updateExchangeRate(Currency _currency, uint256 _newRate) public onlyOwner {
        require(_currency != Currency.ETH, "Cannot update ETH rate");
        require(_newRate > 0, "Rate must be greater than 0");
        
        exchangeRates[_currency] = _newRate;
        emit ExchangeRateUpdated(_currency, _newRate);
    }
    
    // Withdraw all accumulated tips (owner only)
    function withdrawTips() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");

        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Transfer failed");

        emit Withdrawal(owner, balance);
    }
    
    /**
     * @dev Withdraw a specific amount (owner only)
     * @param _amount Amount to withdraw in Wei
     */
    function withdrawAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = payable(owner).call{value: _amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(owner, _amount);
    }
    
    /**
     * @dev Get total number of tips received
     * @return Number of tips
     */
    function getTipCount() public view returns (uint256) {
        return tips.length;
    }
    
    /**
     * @dev Get tip details by index
     * @param _index Index of the tip
     * @return Tip details
     */
    function getTip(uint256 _index) public view returns (
        address,
        uint256,
        Currency,
        uint256,
        string memory
    ) {
        require(_index < tips.length, "Invalid tip index");
        Tip memory tip = tips[_index];
        return (tip.tipper, tip.amount, tip.currency, tip.timestamp, tip.message);
    }
    
    /**
     * @dev Get all tips from a specific tipper
     * @param _tipper Address of the tipper
     * @return Array of tip indices
     */
    function getTipsByTipper(address _tipper) public view returns (uint256[] memory) {
        uint256 count = 0;
        
        // First pass: count tips from this tipper
        for (uint256 i = 0; i < tips.length; i++) {
            if (tips[i].tipper == _tipper) {
                count++;
            }
        }
        
        // Second pass: collect tip indices
        uint256[] memory tipIndices = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < tips.length; i++) {
            if (tips[i].tipper == _tipper) {
                tipIndices[index] = i;
                index++;
            }
        }
        
        return tipIndices;
    }
    
    /**
     * @dev Get contract balance
     * @return Balance in Wei
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get statistics about the tip jar
     * @return totalTips Total tips in Wei
     * @return tipCount Number of tips
     * @return balance Current contract balance
     */
    function getStats() public view returns (
        uint256 totalTips,
        uint256 tipCount,
        uint256 balance
    ) {
        return (totalTipsReceived, tips.length, address(this).balance);
    }
    
    // Fallback function to accept direct ETH transfers
    receive() external payable {
        tipInETH("Direct transfer");
    }
}