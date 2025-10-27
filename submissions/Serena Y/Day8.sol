//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract TipJar{
    address public owner;
    uint256 public totalTipsReceived;

    mapping(string=>uint256) public conversionRates;//货币名称映射对应的汇率

    mapping(address=>uint256) public tipPerPerson;//地址映射给了多少小费
    string[] public supportedCurrencies;
    mapping(string=>uint256) public tipsPerCurrency;//每种小费的金额

    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007ETH ETH
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
//加入支持货币
     function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");

    //检查当前货币存在与否
        bool currencyExists = false;
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                currencyExists = true;
                break;
            }
        }
//如果货币不存在
         if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;//始终更新汇率
    }
    //换算成ETH
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
        //If you ever want to show human-readable ETH in your frontend, divide the result by 10^18 :
    }
//给Eth消费
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;//每个人给的消费
        totalTipsReceived += msg.value;//一共收到的消费
        tipsPerCurrency["ETH"] += msg.value;//一共收到eth的小费
    }
//其它货币给的消费
     function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");//我要求用户实际发送的以太币数量（msg.value）必须精确地等于合约根据汇率或价格计算出来的所需以太币数量（ethAmount）。如果两者不相等，则交易失败，并显示错误信息 Sent ETH doesn't match the converted amount。”
        tipPerPerson[msg.sender] += msg.value;//每个人给的消费
        totalTipsReceived += msg.value;//一共收到的消费
        tipsPerCurrency[_currencyCode] += _amount;//每种货币给了多少钱
    }
//提取小费
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;//获取并存储当前智能合约地址中持有的所有以太币（ETH）的总量
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalTipsReceived = 0;
    }
//transfer owner
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
//获取支持货币
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }
    //获取余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
//获取给小费的人地址
     function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }
//每种货币有多少小费
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }
//获取货币的汇率
     function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}
