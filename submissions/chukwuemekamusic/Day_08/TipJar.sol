// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract TipJar {
    error TipJar_Unauthorized();
    error TipJar_InvalidAmount();
    error TipJar_InvalidConversionRate();
    error TipJar_CurrencyMissing();
    error TipJar_MoneyNotMatching();
    error TipJar_WithdrawFailed();

    uint256 public constant CURRENCY_PRECISION_DECIMALS = 8;
    uint256 private constant CURRENCY_SCALING_FACTOR = 10 ** CURRENCY_PRECISION_DECIMALS;

    struct ConversionRate {
        uint256 exchangeRate; // Rate in wei per unit currency (scaled by CURRENCY_SCALING_FACTOR)
        bool exists;
    }

    mapping(string => ConversionRate) private s_exchangeRates;
    mapping(address => uint256) public contributions;
    
    uint256 public totalContributions;
    address private immutable i_owner;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert TipJar_Unauthorized();
        _;
    }

    modifier checkIfCurrencyExists(string memory _currencyName) {
        if (!s_exchangeRates[_currencyName].exists || s_exchangeRates[_currencyName].exchangeRate == 0) {
            revert TipJar_CurrencyMissing();
        }
        _;
    }

    event ExchangeRateSet(string indexed currencyName, uint256 exchangeRate);
    event TipInCurrency(address indexed sender, string indexed currencyName, uint256 currencyAmount, uint256 weiAmount);
    event TipInEth(address indexed sender, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);

    constructor() {
        i_owner = msg.sender;

        // Set initial exchange rates (example rates)
        // USD: 1 USD = 0.0005 ETH (assuming ETH = $2000)
        s_exchangeRates["USD"] = ConversionRate(5e14, true); // 0.0005 * 10^18 / 10^8
        
        // EUR: 1 EUR = 0.0006 ETH (assuming EUR is stronger than USD)
        s_exchangeRates["EUR"] = ConversionRate(6e14, true); // 0.0006 * 10^18 / 10^8
    }

    /**
     * @notice Set exchange rate for a currency
     * @param _currencyName Name of the currency (e.g., "USD", "EUR")
     * @param _exchangeRate Exchange rate in wei per unit currency (scaled by CURRENCY_SCALING_FACTOR)
     */
    function setExchangeRate(string memory _currencyName, uint256 _exchangeRate) external onlyOwner {
        if (_exchangeRate == 0) revert TipJar_InvalidConversionRate();
        
        s_exchangeRates[_currencyName] = ConversionRate(_exchangeRate, true);
        emit ExchangeRateSet(_currencyName, _exchangeRate);
    }

    /**
     * @notice Get exchange rate for a currency
     * @param _currencyName Name of the currency
     * @return Exchange rate in wei per unit currency (scaled)
     */
    function getExchangeRate(string memory _currencyName) external view returns (uint256) {
        if (!s_exchangeRates[_currencyName].exists) revert TipJar_CurrencyMissing();
        return s_exchangeRates[_currencyName].exchangeRate;
    }

    /**
     * @notice Convert foreign currency amount to wei
     * @param _currencyName Name of the currency
     * @param _amount Amount in the foreign currency (scaled by CURRENCY_SCALING_FACTOR)
     * @return Equivalent amount in wei
     */
    function convertForeignCurrencyToWei(string memory _currencyName, uint256 _amount) 
        public 
        view 
        checkIfCurrencyExists(_currencyName) 
        returns (uint256) 
    {
        if (_amount == 0) revert TipJar_InvalidAmount();
        
        // Calculate: (exchangeRate * amount) / CURRENCY_SCALING_FACTOR
        uint256 weiAmount = (s_exchangeRates[_currencyName].exchangeRate * _amount) / CURRENCY_SCALING_FACTOR;
        return weiAmount;
    }

    /**
     * @notice Tip in a foreign currency (user specifies currency amount, sends equivalent ETH)
     * @param _currencyName Name of the currency
     * @param _amount Amount in the foreign currency (scaled by CURRENCY_SCALING_FACTOR)
     */
    function tipInCurrency(string memory _currencyName, uint256 _amount) 
        external 
        payable 
        checkIfCurrencyExists(_currencyName) 
    {
        if (_amount == 0) revert TipJar_InvalidAmount();
        
        uint256 expectedWei = convertForeignCurrencyToWei(_currencyName, _amount);
        if (msg.value != expectedWei) revert TipJar_MoneyNotMatching();
        
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        
        emit TipInCurrency(msg.sender, _currencyName, _amount, msg.value);
    }

    /**
     * @notice Tip directly in ETH
     */
    function tipInEth() external payable {
        if (msg.value == 0) revert TipJar_InvalidAmount();
        
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        
        emit TipInEth(msg.sender, msg.value);
    }

    /**
     * @notice Get the contribution amount for a specific address
     * @param _contributor Address of the contributor
     * @return Amount contributed by the address
     */
    function getContribution(address _contributor) external view returns (uint256) {
        return contributions[_contributor];
    }

    /**
     * @notice Get the contract's current balance
     * @return Contract balance in wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Withdraw all funds to owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert TipJar_InvalidAmount();
        
        (bool success, ) = payable(i_owner).call{value: balance}("");
        if (!success) revert TipJar_WithdrawFailed();
        
        emit Withdrawal(i_owner, balance);
    }

    /**
     * @notice Get the owner address
     * @return Owner address
     */
    function getOwner() external view returns (address) {
        return i_owner;
    }

    /**
     * @notice Check if a currency exists
     * @param _currencyName Name of the currency
     * @return True if currency exists
     */
    function currencyExists(string memory _currencyName) external view returns (bool) {
        return s_exchangeRates[_currencyName].exists;
    }

    /**
     * @notice Receive function - called when ETH is sent directly to contract with no data
     * @dev This allows users to send ETH directly to the contract address as a tip
     */
    receive() external payable {
        if (msg.value == 0) revert TipJar_InvalidAmount();
        
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        
        emit TipInEth(msg.sender, msg.value);
    }

    /**
     * @notice Fallback function - called when ETH is sent with data that doesn't match any function
     * @dev This catches any ETH sent with invalid function calls and treats it as a tip
     */
    fallback() external payable {
        if (msg.value == 0) revert TipJar_InvalidAmount();
        
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        
        emit TipInEth(msg.sender, msg.value);
    }
}