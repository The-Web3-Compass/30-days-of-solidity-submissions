// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TipJar {
    address public immutable owner;
    mapping(string => uint256) public conversionRates;
    mapping(string => bool) private currencyExists;
    string[] public supportedCurrencies;
    uint256 public totalTipReceived;
    mapping(address => uint256) public tipPerContributor;
    mapping(string => uint256) public tipPerCurrency;
    
    // Reentrancy guard
    bool private locked;

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
    
    modifier nonReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than zero");
        
        if (!currencyExists[_currencyCode]) {
            supportedCurrencies.push(_currencyCode);
            currencyExists[_currencyCode] = true;
            emit CurrencyAdded(_currencyCode, _rateToEth);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        
        uint256 ethAmount;
        unchecked {
            ethAmount = _amount * conversionRates[_currencyCode];
        }
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

        tipPerContributor[msg.sender] += msg.value;
        totalTipReceived += msg.value;
        tipPerCurrency[_currencyCode] += _amount;

        emit TipReceived(msg.sender, _amount, _currencyCode);
    }

    function withdrawTips() public nonReentrant onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");

        uint256 amountToWithdraw = contractBalance;
        totalTipReceived = 0;

        (bool success, ) = payable(owner).call{value: amountToWithdraw}("");
        require(success, "Transfer failed");

        emit TipsWithdrawn(owner, amountToWithdraw);
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
    
    function isCurrencySupported(string memory _currencyCode) public view returns (bool) {
        return currencyExists[_currencyCode];
    }
}