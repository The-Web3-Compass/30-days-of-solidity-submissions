//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    uint256 public totalTipsReceived;
    mapping(string => uint256) public conversionRates;
    mapping(address => uint256) public tipPerPerson;
    string[] public supportedCurrencies;  
    mapping(string => uint256) public tipsPerCurrency;
    
    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14); 
        addCurrency("EUR", 6 * 10**14);  
        addCurrency("JPY", 4 * 10**12);  
        addCurrency("INR", 7 * 10**12);  
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function addCurrency(string memory currencyName, uint256 rateToEth) public onlyOwner {
        require(rateToEth > 0, "Conversion rate must be greater than 0");
        bool currencyExists = false;
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(currencyName))) {
                currencyExists = true;
                break;
            }
        }
        if (!currencyExists) {
            supportedCurrencies.push(currencyName);
        }
        conversionRates[currencyName] = rateToEth;
    }
    function convertToEth(string memory currencyName, uint256 amount) public view returns (uint256) {
        require(conversionRates[currencyName] > 0, "Currency not supported");
        uint256 ethAmount = amount * conversionRates[currencyName];
        return ethAmount;
    }
function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }
    
function tipInCurrency(string memory currencyName, uint256 amount) public payable {
        require(conversionRates[currencyName] > 0, "Currency not supported");
        require(amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(currencyName, amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[currencyName] += amount;
    }

    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalTipsReceived = 0;
    }
  
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }
    

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
   
    function getTipPerPerson(address tipper) public view returns (uint256) {
        return tipPerPerson[tipper];
    }
    

    function getTipsInCurrency(string memory currencyName) public view returns (uint256) {
        return tipsPerCurrency[currencyName];
    }

    function getConversionRate(string memory currencyName) public view returns (uint256) {
        require(conversionRates[currencyName] > 0, "Currency not supported");
        return conversionRates[currencyName];
    }
}