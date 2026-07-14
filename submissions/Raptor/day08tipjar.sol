// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract tipJar{
    address public owner;
    uint256 public totalReceived;

    mapping(string=>uint256) public conversionRates;
    mapping(address=>uint256) public tipPerPerson;
    string[] public supportedCurrencies;
    mapping(string=>uint256) public tipsPerCurrency;

    constructor(){
        owner=msg.sender;
        addCurrency("USD",5 * 10**14);//1 USD = 0.0005 ETH
        addCurrency("LOB Point",1 * 10**15);//1 LOB Point = 0.001 ETH
    }

    modifier onlyOwner{
        require(msg.sender==owner,"Only owner can call this function");
        _;  
    }

    function addCurrency(string memory _currencyCode,uint256 _rateToEth) public onlyOwner{
        require(_rateToEth > 0,"Conversion rate must be greater than zero");
        bool currencyExists = false;

        for(uint i = 0; i < supportedCurrencies.length;i++){
            if(keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;
            }
        }

        if(!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }

        conversionRates[_currencyCode] = _rateToEth;

    }

    function tipInEth() public payable{
        require(msg.value > 0,"No money get out");
        tipPerPerson[msg.sender] += msg.value;
        totalReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function tipInCurrency(string memory _currencyCode,uint256 _amount)public payable{
        require(conversionRates[_currencyCode] > 0,"Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = getConvertionToEth(_currencyCode, _amount)* 10**18;
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value;
        totalReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalReceived = 0;
    }

    function getConvertionToEth(string memory _currencyCode,uint256 _amount)public view returns(uint256){
        require(conversionRates[_currencyCode] > 0,"Currency not supported");
        uint256 readableEthAmount = _amount * conversionRates[_currencyCode] / (10**18);
        return readableEthAmount;
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