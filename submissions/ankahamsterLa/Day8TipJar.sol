//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


// Handling real-world currencies inside smart contract: dealing with ETH and wei, do math conversion safely and ensure users send the correct amount of ETH
contract TipJar{
    address public owner; // keep track of deployer
    uint256 public totalTipsReceived; // This variable tells us how much ETH (in wei) the contract has collected overall.

    // For example, if 1 USD = 0.0005 ETH, then the rate would be 5 * 10^14
    mapping(string=>uint256) public conversionRates;// currency_name=>conversion rate between currency and eth
    mapping(address=>uint256) public tipPerPerson;// This stores how much ETH each address has sent in tips: person who send tips=>tips
    string[] public supportedCurrencies;//List of supported currencies
    mapping(string=>uint256) public tipsPerCurrency;// This tracks how much was tipped in each currency.currency_name=> amounts of tipped currency

    constructor(){
        owner=msg.sender;
         
        // 1 ETH = 1,000,000,000,000,000,000 wei = 10^18 wei, wei is the smallest unit of eth.
        // It is general to convert and transfer eth in wei unit.
        // Solidity can not deal with decimal data. Decimal data cannot keep consistent which probably has risks of data overflow and tiny data error in every distributed node and takes large amount of gas fee in blockchain.
        addCurrency("USD",5*10**14); // 1 USD = 0.0005 ETH
        addCurrency("EUR",6*10**14); // 1 EUR = 0.0006 ETH
        addCurrency("JPY",4*10**12); // 1 JPY = 0.000004 ETH
        addCurrency("INR",7*10**12); // 1 INR = 0.000007ETH
        
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }

    // Add or update a supported currency
    function addCurrency(string memory _currencyCode,uint256 _rateToEth) public onlyOwner{
        require(_rateToEth>0,"Conversion rate must be greater than 0");
        bool currencyExists=false;
        for(uint i=0;i<supportedCurrencies.length;i++){
            // Convert them to bytes using "bytes(...)", and then pass those bytes into "keccak256()" — Solidity’s built-in cryptographic hash function. 
            // In solidity, it is not direct to compare string or bytes which has dynamic length. So it's a wise way to convert string to keccak256 data type to compare.
            if(keccak256(bytes(supportedCurrencies[i]))==keccak256(bytes(_currencyCode))){
                currencyExists=true;
                break;
            }
        }

        if(!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode]=_rateToEth;
    }

    // Caculate the amounts of eth through the conversion rate between currencies and eth
    function convertToEth(string memory _currencyCode,uint256 _amount) public view returns(uint256){
        require(conversionRates[_currencyCode]>0,"Currency not supported");
        uint256 ethAmount=_amount*conversionRates[_currencyCode];
        return ethAmount;
        // If you ever want to show human-readable ETH in your frontend, divide the result by 10^18;
    }

    // Send a tip in ETH directly
    function tipInEth() public payable{
        require(msg.value>0,"Tip amount must be greater than 0");
        tipPerPerson[msg.sender]+=msg.value;
        totalTipsReceived+=msg.value;
        tipsPerCurrency["ETH"]+=msg.value;
    }


    function tipInCurrency(string memory _currencyCode,uint256 _amount) public payable{
        require(conversionRates[_currencyCode]>0,"Currency not supported ");                                                                                                                                                                                                                                     
        require(_amount>0,"Amount must be greater than 0");
        uint256 ethAmount=convertToEth(_currencyCode,_amount);
        require(msg.value==ethAmount,"Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender]+=msg.value;
        totalTipsReceived+=msg.value;
        tipsPerCurrency[_currencyCode]+=_amount;
    }

    // Withdraw tips from contracts.
    function withdrawTips() public onlyOwner{
        uint256 contractBalance=address(this).balance;
        require(contractBalance>0,"No tips to withdraw");
        (bool success,)=payable(owner).call{value:contractBalance}("");
        require(success,"Transfer failed");
        totalTipsReceived=0;
    }

    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner!=address(0),"Invalid address");
        owner=_newOwner;
    }

    function getSupportedCurrencies() public view returns(string[] memory){
        return supportedCurrencies;
    }

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns(uint256){
        return tipPerPerson[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns(uint256){
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode) public view returns(uint256){
        require(conversionRates[_currencyCode]>0,"Currency not supported");
        return conversionRates[_currencyCode];
    }



}