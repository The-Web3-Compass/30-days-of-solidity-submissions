// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TipJar {
    address public owner;
    mapping(string => uint256) public conversionRates;
    string[] public supportedCurrencies;
    uint256 public totalTipReceived;
    mapping(address => uint256) public tipPerContributor;
    mapping(string => uint256) public tipPerCurrency;

    event CurrencyAdded(string currencyCode, uint256 rateToEth);
    event TipReceived(address indexed contributor, uint256 amount, string currencyCode);
    event TipsWithdrawn(address indexed owner, uint256 amount);

    constructor() {
        owner = msg.sender;

        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("INR", 4 * 10**12);
        addCurrency("GBP", 3 * 10**12);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than zero");
        bool currencyExists = false;

        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                currencyExists = true;
                break;
            }
        }

        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
            emit CurrencyAdded(_currencyCode, _rateToEth);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    function tipInEth() public payable {
        require(msg.value > 0, "Tip must be greater than zero");

        tipPerContributor[msg.sender] += msg.value;
        totalTipReceived += msg.value;
        tipPerCurrency["ETH"] += msg.value;

        emit TipReceived(msg.sender, msg.value, "ETH");
    }

    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than zero");

        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "ETH amount mismatch");

        tipPerContributor[msg.sender] += _amount;
        totalTipReceived += msg.value;
        tipPerCurrency[_currencyCode] += _amount;

        emit TipReceived(msg.sender, _amount, _currencyCode);
    }

    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");

        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalTipReceived = 0;

        emit TipsWithdrawn(owner, contractBalance);
    }

    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerContributor[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipPerCurrency[_currencyCode];
    }

    function getConversionRates(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Invalid currency");
        return conversionRates[_currencyCode];
    }
}