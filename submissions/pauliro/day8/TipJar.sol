// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
/*
    Build a multi-currency digital tip jar! 
    Users can send Ether directly or simulate tips in foreign currencies like USD or EUR. 
    You'll learn how to manage currency conversion, handle Ether payments using `payable` 
    and `msg.value`, and keep track of individual contributions. 
    Think of it like an advanced version of a 'Buy Me a Coffee' button — but smarter, 
    more global, and Solidity-powered.

    Learning Progression
    Expands on basic Ether transfers by introducing access control, 
    tracking contributions, and simulating real-world currency 
    handling — preparing you for more complex contract logic.
*/

contract TipJar {
    uint256 totalTips;
    address public owner;
    string[] public supportedCurrencies;

    mapping(string => uint256) public conversionRates;
    mapping(address => uint256) public tipPerPerson;
    mapping(string => uint256) public tipsPerCurrency;
    
      
    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("GBP", 7 * 10**14);  // 1 INR = 0.000007ETH ETH
        addCurrency("UYU", 56 * 10**12); // 1 UYU = 0.0000056 ETH
        addCurrency("ARs", 16 * 10**12); // 1 ARG = 0.000000160 ETH
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
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
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }

    // Add or update a supported currency
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");
        bool currencyExists = false;
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                currencyExists = true;
                break;
            }
        }
        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }
        
        conversionRates[_currencyCode] = _rateToEth;
    }
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
        //If you ever want to show human-readable ETH in your frontend, divide the result by 10^18 :
    }

    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalTips = 0;
    }

    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value;
        totalTips += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTips += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }
}