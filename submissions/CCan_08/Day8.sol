// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar{
    address public owner;
    uint256 public totalTipsReceived;
    mapping (string => uint256) public conversionRates;
    mapping (address => uint256) public tipPerPerson;
    string[] public supportedCurrencies; // from 货币代码 to ETH 的汇率
    mapping (string => uint256) public tipsPerCurrency;

    constructor() {
        owner=msg.sender;
        addCurrency("USD", 5 * 10**14);//0.0005 ETH (1ETH = 10**18 wei)
        addCurrency("EUR", 4 * 10**14);//0.0004 ETH
        addCurrency("GBP", 3 * 10**14);//0.0003 ETH
    }

    //修饰符，确保只有合约所有者可以调用某些函数
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    //验证费率；验证货币是否存在，避免重复添加相同的货币
 function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
    require(_rateToEth > 0, "conversion rate must be greater than 0");
    bool currencyExists = false; // Fixed typo: `currencyExistes` → `currencyExists`
    for (uint i = 0; i < supportedCurrencies.length; i++) {
        if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
            currencyExists = true;
            break;
        }
    }
    if (!currencyExists) { // Moved inside the function
        supportedCurrencies.push(_currencyCode);
        conversionRates[_currencyCode] = _rateToEth; // Typo: `coversionRates` → `conversionRates` (also fix elsewhere)
    }
}

//汇率转换
function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256){
    require(conversionRates[_currencyCode]>0,"Currency not supported.");
    uint256 ethAmount = _amount * conversionRates[_currencyCode];
    return ethAmount;
}

function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }
    
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
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
}