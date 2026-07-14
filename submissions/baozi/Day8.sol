// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    uint256 public totalTipsReceived;

    mapping(string => uint256) public conversionRates; // currencyCode => rate (ETH per unit)
    string[] public supportedCurrencies;

    mapping(string => uint256) public tipsPerCurrency; // currencyCode => total in that currency
    mapping(address => uint256) public tipPerPerson;

    // Events
    event Tipped(address indexed tipper, uint256 amountEth, string currency, uint256 originalAmount);
    event TipInEth(address indexed tipper, uint256 amountEth);
    event Withdrawn(address indexed owner, uint256 amount);
    event CurrencyAddedOrUpdated(string currency, uint256 rate);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("INR", 7 * 10**12);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Add or update a currency conversion rate
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Rate must be > 0");

        if (conversionRates[_currencyCode] == 0) {
            supportedCurrencies.push(_currencyCode);
        }

        conversionRates[_currencyCode] = _rateToEth;

        emit CurrencyAddedOrUpdated(_currencyCode, _rateToEth);
    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        uint256 rate = conversionRates[_currencyCode];
        require(rate > 0, "Unsupported currency");
        return _amount * rate;
    }

    // Tip directly in ETH
    function tipInEth() public payable {
        require(msg.value > 0, "Tip must be > 0");

        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;

        emit TipInEth(msg.sender, msg.value);
    }

    // Tip using fiat-equivalent, converted to ETH
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(_amount > 0, "Amount must be > 0");
        require(conversionRates[_currencyCode] > 0, "Unsupported currency");

        uint256 expectedEth = _amount * conversionRates[_currencyCode];
        require(msg.value == expectedEth, "ETH sent does not match conversion");

        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;

        emit Tipped(msg.sender, msg.value, _currencyCode, _amount);
    }

    function withdrawTips() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");

        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdraw failed");

        emit Withdrawn(owner, balance);
        totalTipsReceived = 0;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    // View functions
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Unsupported currency");
        return conversionRates[_currencyCode];
    }

    // Prevent accidental ETH transfers
    receive() external payable {
        revert("Use tipInEth or tipInCurrency to send ETH");
    }

    fallback() external payable {
        revert("Fallback not supported");
    }
}
