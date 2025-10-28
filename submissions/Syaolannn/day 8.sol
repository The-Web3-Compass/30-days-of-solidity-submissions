//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar{

    address public owner;
    uint256 public totalTipReceived;
    mapping(string => uint256)public conversionRates;
    mapping(address => uint256) public tipPerPerson;
    string[] public supportedCurrencies; //保存支持的货币代码列表
    mapping(string => uint256) public tipsPerCurrency;
    
    constructor(){
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005ETH
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("CNY", 245 * 10**12);
        addCurrency("AUD", 1590 * 10**12);
    }

    modifier onlyOwner(){
       require(msg.sender == owner, "Only owner can perform this action");
       _;
     }

    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner{
       require(_rateToEth > 0, "Conversion rate must be greater than 0");
       bool currencyExists = false; //假设还没有这种货币
       for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true; //寻找到这种货币，循环结束
                break;
            }
        }
        if (!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth; //conversionRates = 货币兑换成 ETH 的速算表
    }

    function converToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
       require (conversionRates[_currencyCode] > 0, "Currency not supported");
       uint ethAmount = _amount * conversionRates[_currencyCode];
       return ethAmount;
    }

    //直接发送eth小费
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTipReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable{
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = converToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value;
        totalTipReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalTipReceived = 0;
    }

    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner !=address(0), "Invalid address");
        owner= _newOwner;
    }

    function getSupportedCurrencies() public view returns (string[] memory){
        return supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256){
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns (uint256){
        return tipPerPerson[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256){
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode) public view returns (uint256){
        require(conversionRates[_currencyCode] >0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}