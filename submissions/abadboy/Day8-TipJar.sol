// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title TipJar - A contract for receiving and managing tips in ETH and other currencies
contract TipJar {
    /// @notice The address of the contract owner
    address public owner;

    /// @notice Total amount of ETH received as tips (in Wei)
    uint256 public totalTipsReceived;

    /// @notice Conversion rates from supported currencies to ETH (in Wei)
    mapping(string => uint256) public conversionRates;

    /// @notice Tracks whether a currency is supported
    mapping(string => bool) private currencyExists;

    /// @notice List of supported currency codes
    string[] public supportedCurrencies;

    /// @notice Tracks tips received per person (in Wei)
    mapping(address => uint256) public tipPerPerson;

    /// @notice Tracks tips received per currency (in Wei for consistency)
    mapping(string => uint256) public tipsPerCurrency;

    /// @notice Emitted when a new currency is added or updated
    event CurrencyAdded(string currencyCode, uint256 rateToEth);

    /// @notice Emitted when a tip is received
    event TipReceived(address indexed tipper, string currencyCode, uint256 amount, uint256 ethAmount);

    /// @notice Emitted when tips are withdrawn
    event TipsWithdrawn(address indexed owner, uint256 amount);

    /// @notice Emitted when ownership is transferred
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @notice Initializes the contract with predefined currencies
    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14); // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14); // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12); // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12); // 1 INR = 0.000007 ETH
    }

    /// @notice Restricts function access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    /// @notice Adds or updates a supported currency
    /// @param _currencyCode The currency code (e.g., "USD")
    /// @param _rateToEth Conversion rate to ETH (in Wei)
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");
        if (!currencyExists[_currencyCode]) {
            supportedCurrencies.push(_currencyCode);
            currencyExists[_currencyCode] = true;
        }
        conversionRates[_currencyCode] = _rateToEth;
        emit CurrencyAdded(_currencyCode, _rateToEth);
    }

    /// @notice Converts an amount in a given currency to ETH (in Wei)
    /// @param _currencyCode The currency code
    /// @param _amount Amount in the specified currency
    /// @return The equivalent amount in Wei
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return _amount * conversionRates[_currencyCode];
    }

    /// @notice Allows users to send tips in ETH
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
        emit TipReceived(msg.sender, "ETH", msg.value, msg.value);
    }

    /// @notice Allows users to send tips in a supported currency
    /// @param _currencyCode The currency code
    /// @param _amount Amount in the specified currency
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += ethAmount; // Store in Wei for consistency
        emit TipReceived(msg.sender, _currencyCode, _amount, msg.value);
    }

    /// @notice Allows the owner to withdraw all tips
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        totalTipsReceived = 0; // Update state before transfer
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        emit TipsWithdrawn(owner, contractBalance);
    }

    /// @notice Transfers ownership to a new address
    /// @param _newOwner The new owner's address
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /// @notice Returns the list of supported currencies
    /// @return Array of currency codes
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    /// @notice Returns the contract's ETH balance
    /// @return Balance in Wei
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the total tips contributed by a specific address
    /// @param _tipper The tipper's address
    /// @return Total tips in Wei
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }

    /// @notice Returns the total tips received in a specific currency
    /// @param _currencyCode The currency code
    /// @return Total tips in Wei
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    /// @notice Returns the conversion rate for a specific currency
    /// @param _currencyCode The currency code
    /// @return Conversion rate to ETH (in Wei)
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}