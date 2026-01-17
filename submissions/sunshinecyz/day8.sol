// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar{
    address public owner ;

    //货币到eth的汇率（一个货币对应多少eth）
    mapping(string => uint256) public conversionRates;

    //货币列表
    string[] public supportedCurrencies;

    //eth总量
    uint256 public totalTipsReceived;

    //存储了每个地址发送了多少 ETH 打赏
    mapping(address=>uint256) public tipperContributions;
    //存储了每个其他货币对应的金额
    mapping(string => uint256) public tipsPerCurrency;

    modifier onlyOwner(){
        require(msg.sender == owner ,"only owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        addCurrency("USD", 5*10**14);
        addCurrency("EUR", 6*10*14);
        addCurrency("JPY", 4*10**12);
        addCurrency("GBP",7*10**14);
    }



    function addCurrency(string memory _currencyCode, uint256  _ratetoEth) public onlyOwner{
        require(_ratetoEth > 0, "conversion rate must be greater than 0");

        bool currencyExists = false ;
        //判断此次添加的货币是否已经存在
        for( uint i = 0 ; i< supportedCurrencies.length;i++){   
            if(keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;
            }
        }

        //如果不存在，则添加进列表中
        if(!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }
        //设置兑换率
        conversionRates[_currencyCode] = _ratetoEth;
    }


    function covertToEth(string memory _currencyCode, uint256 _amount) public view  returns(uint256){
        require(conversionRates[_currencyCode] > 0,"currency doesn't exist");

        uint256 ethAmount  = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }   

    //打小费
    function tipInEth() public payable {
        require(msg.value > 0, "must be greater than 0");
         
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }
    
    //以其他货币打赏
    function tipInCurrency(string memory _currencyCode ,uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0,"must be greater than 0");
        require(_amount > 0,"must be greater than 0");

        uint256 ethAmount = covertToEth(_currencyCode,_amount);

        require(msg.value  == ethAmount, "sent eth doesn't match the converted amount");
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount ;
    }

    //提取所有的小费
    function withdrawTips() public onlyOwner{
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0 ,"no tips ");
        
        (bool success ,) = payable(owner).call{value:contractBalance}("");
        require(success,"failed");
        totalTipsReceived = 0;
    }   

    //转移owner
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0),"invalid address");
        owner = _newOwner;
    }

    function getSupportedCurrencies() public view returns(string[] memory){
        return  supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256){
        return  address(this).balance;
    }


    function getTipperContribution(address _tipper) public view returns (uint256){
        return tipperContributions[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256){
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode ) public view returns(uint256){
        require(conversionRates[_currencyCode] >0 ,"currency not dupported");
        return conversionRates[_currencyCode];
    }


}