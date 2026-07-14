// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract tipJar{

    address public owner;
    string[] public supportedCurrency;
    mapping (string=> uint256) public conversionRates;
    uint256 public tipsTotalReceived;
    mapping (address=>uint256) public tipsPerPerson;
    mapping (string =>uint256) public tipsPerCurrency;

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }

    constructor(){
         owner = msg.sender;
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH  1 ETH=10^18 wei
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007ETH ETH
    }
    
    


    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {

        require(_rateToEth>0,"Conversion rate must be greater than 0");
        //  注意此处是需要赋值，而不是进行判断
        bool currencyExists =false;     
        // #这是循环函数 初始为0                   
        for (uint256 i=0;i< supportedCurrency.length; i++){     
           
           //solidity特殊的哈希函数，需要将string转换为字节byte           
           if (keccak256 (bytes (supportedCurrency[i]))== keccak256(bytes(_currencyCode))) {
              currencyExists = true;
              break;
        
           }   
        }

        if (!currencyExists){
            supportedCurrency.push(_currencyCode);
        }

        conversionRates[_currencyCode]=_rateToEth;
       
    }

    function convertEth (string memory _currencycode, uint256 _amount) public view returns(uint256){
        require(conversionRates[_currencycode] >0, "Currency not supported");
        uint256 ethAmount= _amount* conversionRates[_currencycode];
        return ethAmount;
    }

    function tipInEth () public payable {
        require(msg.value>0, "Tip must be greater than 0");
        tipsPerPerson[msg.sender] += msg.value;
        tipsTotalReceived += msg.value;
        tipsPerCurrency["ETH"]+= msg.value;

    }

    function tipInCurrency (string memory _currencycode, uint256 _amount) public payable {
         require(conversionRates[_currencycode] >0, "Currency not supported");
         require(_amount>0,"Tip must be greater than 0");
         uint256 ethAmount= convertEth(_currencycode, _amount);
         //再次检查交易是否有错误
         require(msg.value==ethAmount,"Sent ETH doesn't match the converted amount");
         tipsPerPerson[msg.sender] += msg.value;
         tipsTotalReceived += msg.value;
         tipsPerCurrency[_currencycode]+= _amount;

    } 

    function withdrawlTips () public onlyOwner{
        uint256 contractbalance=address(this).balance;
        require(contractbalance >0,"No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractbalance}("");
        require(success, "Transfer failed");
        tipsTotalReceived = 0;
    }

    function transferOwnership (address _newOwner) public onlyOwner{
        require( _newOwner != address(0), "Invalid address");
        owner=_newOwner;
    }

//获取合约信息 （）是调用函数，[]是访问数组和mapping的元素
    function getSuppotedCurrency() public view returns (string[] memory){

        return supportedCurrency;
    }

    function getContractBalance()public view  returns (uint256){

        return address(this).balance;
    }

    function getTipperContribution(address _Tipper) public view returns(uint256) {

        return tipsPerPerson[_Tipper];
    }

    function getTipsInCurrency (string memory _currencycode) public view returns (uint256){

        return tipsPerCurrency[_currencycode];
    }

    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }



}
