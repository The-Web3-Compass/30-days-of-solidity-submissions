// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TipJar{
    address public owner;

    string[] public supportedCurrencies;
    mapping (string => uint256) public  conversionRates;

    uint256 public  totalTipsReceived;

    mapping (address => uint256) public tipperContributions;

    mapping(string => uint256) public tipsPerCurrency;

    constructor(){
        owner = msg.sender;

        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can perform this action");
        _;
    }

    //No read and modify states
    //So this is a pure function
    function isEqual(string memory _s1,string memory _s2)private pure returns (bool){
        return keccak256(bytes(_s1)) == keccak256(bytes(_s2));
    }

    function addCurrency(string memory _currencyCode,uint256 _rateToEth) public onlyOwner{
        require(_rateToEth>0,"RateToEth should be greater than 0");
        require(!isEqual(_currencyCode,""),"CurrencyCode is a empty string");

        bool currencyIsExist = false;

        for (uint i = 0; i<supportedCurrencies.length;i++){
            if(isEqual(_currencyCode,supportedCurrencies[i])){
                currencyIsExist = true;
                break ;
            }
        }

        if(!currencyIsExist){
            supportedCurrencies.push(_currencyCode);
            conversionRates[_currencyCode] = _rateToEth;
        }
    }

    function convertToEth(string memory _currencyCode,uint256 _amount)private view returns (uint256){
        require(conversionRates[_currencyCode] > 0,"Currency is not supported");
        return _amount*conversionRates[_currencyCode];
    }

    function tipInEth() external payable {
        totalTipsReceived+=msg.value;
        tipperContributions[msg.sender]+=msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function tipInCurrency(string memory _currencyCode,uint256 _amount)external payable {
        require(conversionRates[_currencyCode] > 0,"Currency is not supported");
        require(_amount>0,"Amount should be greater than 0");

        uint256 ETHAmount = convertToEth(_currencyCode, _amount);
        require(ETHAmount == msg.value,"Sent ETH doesn't match the converted amount");

        totalTipsReceived += msg.value;
        tipperContributions[msg.sender] += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    function withdrawTips() public onlyOwner{
        //"this" is the address of the contract
        //get the balance of this contract
        uint256 currentContractBalance = address(this).balance;
        require(currentContractBalance>0,"No tips to withdraw");
        
        (bool success,) = payable (owner).call{value:currentContractBalance}("");

        require(success, "Transfer failed");

        totalTipsReceived = 0;
    }

    function transferOwnership(address _newOwner)public onlyOwner{
        require(_newOwner != address(0),"Invalid address");

        owner = _newOwner;
    }

    function getSupportedCurrencies() public view returns (string[] memory){
        return supportedCurrencies;
    }

    function getContractBalance()public view returns (uint256){
        return address(this).balance;
    }

    function getTipperContribution(address _contributor)public view returns (uint256){
        require(_contributor != address(0),"Invalid address");
        return tipperContributions[_contributor];
    }

    function getTipsInCurrency(string memory _currencyCode)public view returns (uint256){
        require(conversionRates[_currencyCode] > 0,"Currency is not supported");
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode)public view returns (uint256){
        require(conversionRates[_currencyCode] > 0,"Currency is not supported");
        return conversionRates[_currencyCode];
    }
}