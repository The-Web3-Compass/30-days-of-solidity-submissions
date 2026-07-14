// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar{
    address public owner;
    string[] public supportedCurrencies;
    mapping(string => uint256)conversionRates;
    uint256 public totalTipsRecieved;
    mapping (address => uint256)public tipsPerPerson;
    mapping(string => uint256) public tipsPerCurrency;
    mapping(bytes32 => bool) private currencyExistsHash;
    modifier onlyOwner(){
        require(msg.sender == owner, "Only the owner can do it");
        _;
    }

    constructor(){
        owner = msg.sender;
        addCurrency1("USD",5*10**14); // 1 USD = 0.0005 ETH , 1 ETH = 10^18 WEI 
                                    // ==> 0.0005 ETH = 5*10^14 WEI
                                    // ==> 1 USD = 5*10^14 WEI

        addCurrency1("EUR",6*10**14); 
        addCurrency("RMB",4*10**13); 
        addCurrency("JPY",4*10**12); 
    }

    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner{
        require(_rateToEth > 0, "Please enter a number greater than 0");
        bool currencyExists = false;

        // we can not compare two strings with == directly in solidity
        for (uint256 i = 0; i < supportedCurrencies.length; i++){
            if(keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true;
                revert("Currency already exists"); 
            }
        }
                // bytes convert string to bytes
                // use keccak256 hashing to check if two string has same value
                // for loop goes thru the whole exist currencies array

        // if there's no match, push the new currency code to the string array
        if(!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    // =============================== 2nd way to check if currency exists ===============================

    function addCurrency1(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Rate must be greater than 0");

        bytes32 codeHash = keccak256(bytes(_currencyCode));
        require(!currencyExistsHash[codeHash], "Currency already exists");
        
        if (!currencyExistsHash[codeHash]) {
            supportedCurrencies.push(_currencyCode);
            currencyExistsHash[codeHash] = true;
        }


        conversionRates[_currencyCode] = _rateToEth;
    }

    // =============================== 3rd way to check if currency exists ===============================

    mapping(string => bool) existCode;
    function addCurrency2(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Rate must be greater than 0");
        require(!existCode[_currencyCode], "Currency already exists");
        supportedCurrencies.push(_currencyCode);
        conversionRates[_currencyCode] = _rateToEth;
        existCode[_currencyCode] = true;
    }
    
    
    
    
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns(uint256){
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        
        return _amount * conversionRates[_currencyCode];
    }

    function tipInEth() public payable{
        require(msg.value > 0, "Must send more than 0");
        tipsPerPerson[msg.sender] += msg.value;
        totalTipsRecieved += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable{
        require(conversionRates[_currencyCode] >0, "currency is not supported");
        require(_amount > 0, "Must send more than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Must send correct amount of ETH");
        tipsPerPerson[msg.sender] += msg.value;
        totalTipsRecieved += msg.value;
        tipsPerCurrency[_currencyCode] += msg.value;
    }

    function withdrawTips()public onlyOwner{
        uint256 contractBalance = address(this).balance;
        require(contractBalance >0, "No tips :<");
        
        //update balance before transfer
        totalTipsRecieved = 0;
        (bool success,) = payable(owner).call{value: contractBalance}("");
        require(success,"Transfer Failed");
        
    }

    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    function getContractBalance() public view returns  (uint256){
        return address(this).balance;
    }


    function getTipsOfContribution(address _tipper) public view returns(uint256){
        return tipsPerPerson[_tipper];
    }
    
    function getTipsInCurrency(string memory _currencyCode) public view returns(uint256){
        return tipsPerCurrency[_currencyCode];
    }

    function getSupportedCurrencies() public view returns (string[] memory){
        return supportedCurrencies;
}

}