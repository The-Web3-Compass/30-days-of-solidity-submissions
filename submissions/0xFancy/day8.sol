// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar{
    address public owner;
    mapping(string => uint) public conversionRates;
    string[] public supportCurrencies;
    uint256 public totalTipsReceived;
    mapping(address => uint256) public tipperContributions;
    mapping(string => uint256) public tipsPerCurrency;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
   
   function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner{
        require(_rateToEth > 0,"Converion rate must be greater than 0.");
        bool currenctExists = false;
        for (uint i = 0; i < supportCurrencies.length; i++){
            if(keccak256(bytes(supportCurrencies[i]) ) == keccak256(bytes(_currencyCode))){
                currenctExists = true;
                break;
            }
        if(!currenctExists){
            supportCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
        }
   }
    constructor() {
        owner = msg.sender;
        
        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);
    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public  view returns(uint256){
        require(conversionRates[_currencyCode] > 0, "Currency not support.");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    function tipInEth() public payable{
        require(msg.value > 0, "Tip amount must be greater than zero.");
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }
    
    function tipInCurrency(string memory _currencyCode, uint _amount) public payable{
        require(conversionRates[_currencyCode] > 0, "Currency not support.");
        require(_amount > 0, "Tip amount must be greater than zero.");

        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount.");
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    function withDrawTips() public onlyOwner{
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw.");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer Failed.");
        totalTipsReceived = 0;
    }

    function ransferOwnerShip(address _newOwner) public onlyOwner{
        require(_newOwner != address(0), "Invalid address.");
        owner = _newOwner;
    }

    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportCurrencies;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function getTipperContributions(address _tipper) public view returns (uint256) {
        return tipperContributions[_tipper];
    }

    function getTotalTipsReceived() public view returns (uint256) {
        return totalTipsReceived;
    }
    function getTipPerCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported.");
        return conversionRates[_currencyCode];
    }
}