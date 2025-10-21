// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

contract TipJar{

    address public owner;

    mapping(string => uint256) public conversionRates;

    string[] public supportedCurrencies;

    uint256 public totalTipsReceived;


    // This stores how much ETH each address has sent in tips.
    mapping(address => uint256) public tipperContributions;

    // This tracks how much was tipped in each currency.
    mapping(string => uint256) public tipsPerCurrency;

    constructor() {
    owner = msg.sender;
    // 1 ETH = 1,000,000,000,000,000,000 wei = 10^18 wei
    // 0.0005 ETH = 5 * 10**14 wei
    // when you want to display that to a user in ETH (on your frontend),
    // you just divide it back down: uint256 readableEth = rawWei / 10**18;
    addCurrency("USD", 5 * 10**14);
    addCurrency("EUR", 6 * 10**14);
    addCurrency("JPY", 4 * 10**12);
    addCurrency("GBP", 7 * 10**14);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }


    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner{
        require(_rateToEth > 0,"Invalid conversion rate");
        require(bytes(_currencyCode).length != 0,"Invalid currency code");

        conversionRates[_currencyCode] = _rateToEth;

    }

    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }

    function tipInEth() public payable{

        require(msg.value > 0 , "Invalid amount");

        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;

    }

    function tipInCurrency(string memory _currencyCode,uint256 _amount) public payable{
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0 , "Invalid amount");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");

        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;

    }

    function convertToEth(string memory _currencyCode,uint256 _amount) public view returns(uint256 ){
        require(bytes(_currencyCode).length != 0,"Invalid currency code");
        require(_amount > 0,"Invalid amount");
        require(conversionRates[_currencyCode] > 0,"Currency not supported");

        uint256 ethAmount = conversionRates[_currencyCode] * _amount;
        return ethAmount;

    } 

    function withdrawTips() public onlyOwner{
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");

        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success,"Withdraw tips failed");
        totalTipsReceived = 0;
        
    }


    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }


    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipperContributions[_tipper];
    }


}