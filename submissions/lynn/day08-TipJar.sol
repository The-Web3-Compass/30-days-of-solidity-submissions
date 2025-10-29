// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    uint256 public tipsReceived;
    string[] public currenciesSupported;
    mapping(string => uint256) public exchangeRates;
    mapping(address => uint256) public tipsPerAddress;
    mapping(string => uint256) public tipsPerCurrency;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function addCurrency(string memory _currency, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Rate should be greater than 0");
        // check if the currency is already supported, if not, add it into the currenciesSupported list
        // way1:
        // bool isSupported = false;
        // for (uint i = 0; i < currenciesSupported.length; i++) {
        //     if (keccak256(bytes(currenciesSupported[i])) == keccak256(bytes(_currency))) {
        //         isSupported = true;
        //         break;
        //     }
        // }
        // if (!isSupported) {
        //     currenciesSupported.push(_currency);
        // }

        // way2:
        if (exchangeRates[_currency] <= 0) {
            currenciesSupported.push(_currency);
        }

        // update the rate
        exchangeRates[_currency] = _rateToEth;
    }

    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**16);
        addCurrency("GBP", 7 * 10**14);
    }

    function convertToEth(string memory _currency, uint256 _amount) public view returns(uint256) {
        require(exchangeRates[_currency] > 0, "Currency not supported");
        require(_amount > 0, "Amount should be greater than 0");

        return _amount * exchangeRates[_currency];
    }

    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount should be greater than 0");

        tipsReceived += msg.value;
        tipsPerAddress[msg.sender] += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function tipInCurrency(string memory _currency, uint256 _amount) public payable {
        require(_amount > 0, "Tip amount should be greater than 0");
        require(exchangeRates[_currency] > 0, "Currency not supported");
        require(msg.value == _amount * exchangeRates[_currency], "Sent ETH doesn't match the converted amount");

        tipsReceived += msg.value;
        tipsPerAddress[msg.sender] += msg.value;
        tipsPerCurrency[_currency] += _amount;
    }

    function withdrawTips() public onlyOwner {
        uint256 tipBalance = address(this).balance;
        require(tipBalance > 0, "No tips to withdraw");
        // it's ok with owner.balance?
        // require(owner.balance > 0, "No tips to withdraw");

        (bool success, ) = payable(owner).call{value : tipBalance}("");
        require(success, "Withdraw failed");
        //tipsReceived = 0; // I want to record the total tips including any that have been withdrawn, so no reset
    }

    function transferOwner(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner, "Invalid address");
        owner = _newOwner;
    }

    function getSupportedCurrencies() public view returns(string[] memory) {
        return currenciesSupported;
    }

    function getTipBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getTipPerAddress(address _address) public view returns(uint256) {
        require(address(0) != _address, "Invalid address");
        return tipsPerAddress[_address];
    }

    function getTipPerCurrency(string memory _currency) public view returns(uint256) {
        return tipsPerCurrency[_currency];
    }
 
    function getCurrencyRate(string memory _currency) public view returns(uint256) {
        require(exchangeRates[_currency] > 0, "Currency not supported");
        return exchangeRates[_currency];
    }

}