// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract TipJar {
    address manager;
    // 支持的货币
    string[] suppoertedCurrencies;
    // currency -> rate
    mapping(string => uint256) exchangeRate;
    // total tis
    uint256 totalTips;
    // address -> tips
    mapping(address => uint256) addressToTips;
    // currency -> tips
    mapping(string => uint256) currencyToTips;

    constructor() { 
        manager = msg.sender;

        // 1 ether = 10**18 wei
        // 1 gwei = 10**9 wei
        addCurrency("USD", 0.00027 ether);  // ≈ 1 USD = 0.00027 ETH
        addCurrency("JPY", 0.0000018 ether); // ≈ 1 JPY = 0.0000018 ETH
        addCurrency("CNY", 3.8 * 10**13);  // ≈ 1 RMB = 0.000038 ETH
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can perform this action.");
        _;
    }

    function addCurrency(string memory _currencyCode, uint256 rateToETH) public onlyManager {
        require(rateToETH > 0, "Exchange rate must be greather than 0");

        bool exists = false;
        for (uint i = 0; i < suppoertedCurrencies.length; i++) {
            if (keccak256(bytes(suppoertedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            suppoertedCurrencies.push(_currencyCode);
        }
        exchangeRate[_currencyCode] = rateToETH;
    }

    function convertToETH(string memory _currency, uint256 _amount) public view returns (uint256) {
        require(exchangeRate[_currency] > 0, "The currency not supported");
        return _amount * exchangeRate[_currency];
    }

    function tipInETH() public payable {
        require(msg.value > 0, "Tip amount must be > 0");
        addressToTips[msg.sender] += msg.value;
        totalTips += msg.value;
        currencyToTips["ETH"] += msg.value;
    }

    function tipInCurrency(string memory _currency, uint256 _amount) public payable {
        require(exchangeRate[_currency] > 0, "The currency not supported");
        require(_amount > 0, "The amount must be > 0");
        uint256 ethAmount = convertToETH(_currency, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");

        addressToTips[msg.sender] += msg.value;
        totalTips += msg.value;
        currencyToTips[_currency] += _amount;
    }

    function withdrawTips() public onlyManager {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(manager).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalTips = 0;
    }


    function transferManager(address _manager) public onlyManager {
        manager = _manager;
    }

    function getSupportedCurrency() public view returns (string[] memory) {
        return suppoertedCurrencies;
    }

    function getExchangeRate(string memory _currency) public view returns (uint256) {
        return exchangeRate[_currency];
    }

    function getTipsByCurrency(string memory _currency) public view returns (uint256) {
        return currencyToTips[_currency];
    }

    function getTipsByAddress(address _address) public view returns (uint256) {
        return addressToTips[_address];
    }
}