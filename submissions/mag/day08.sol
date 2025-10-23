//SPDX_-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Tipjar {
    address payable public owner;

    uint public totalTips;
    mapping(string => uint) public conversionrates;
    mapping(address => uint) public tipPerPerson;
    string[] public currencies;
    mapping(string => uint) public tipsPerCurrency;
    constructor() {
        owner = msg.sender;
        addCurrency("USD",5*10**14); // 0.0005 ETH
        addCurrency("EUR",6*10**14); // 0.0006 ETH
        addCurrency("RMB",8*10**14); // 0.0008 ETH
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function addCurrency(string memory _currency, uint _rate) public onlyOwner {
        require(_rate > 0, "Conversion rate must be greater than zero");
        bool currencyExists = false;
        for (uint i = 0; i < currencies.length; i++) {
            if (keccak256(bytes(currencies[i])) == keccak256(bytes(_currencyCode))) {
                currencyExists = true;
                break;
            }
        }
        if (!currencyExists) {
            currencies.push(_currencyCode);
        }
        conversionrates[_currency] = _rate;
    }
    function convertToEth(string memory _currencyCode, uint _amount) public view returns (uint) {
        require (conversionrates[_currencyCode] > 0, "Currency not supported");  
        uint ethAmount = (_amount * conversionrates[_currencyCode]);
        return ethAmount;
    }
    function tipInEther() public payable {
        require(msg.value > 0, "Tip amount must be greater than zero");
        totalTips += msg.value;
        tipPerPerson[msg.sender] += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }
    function tipInCurrency(string memory _currencyCode, uint _amount) public {
        require(conversionrates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Tip amount must be greater than zero");
        uint ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH amount does not match converted amount");
        totalTips += ethAmount;
        tipPerPerson[msg.sender] += ethAmount;
        tipsPerCurrency[_currencyCode] += ethAmount;
    }
    function withdrawTips() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed");
        totalTips = 0;
    }
    function getCurrencies() public view returns (string[] memory) {
        return currencies;
    }
    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        owner = _newOwner;
    }
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    function getTipPerPerson(address _tipper) public view returns (uint) {
        return tipPerPerson[_tipper];
    }
    function getTipsPerCurrency(string memory _currencyCode) public view returns (uint) {
        return tipsPerCurrency[_currencyCode];
    }
    function getConversionRate(string memory _currencyCode) public view returns (uint) {
        require(conversionrates[_currencyCode] > 0, "Currency not supported");
        return conversionrates[_currencyCode];
    }
    