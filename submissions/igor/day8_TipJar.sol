// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar{
    address public owner;
    uint256 public totalTipsReceived;
    mapping(string => uint256) public conversionRates;
    mapping(address => uint256) public tipPerPerson;
    string[] public supportedCurrencies;

    constructor(){
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007 ETH
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    //添加支付货币并告知1xxx等于yyy个eth
    function addCurrency(string memory _currencyCode,uint256 _rateToEth)public onlyOwner{
        require(_rateToEth > 0,"Conversion rate must be greater than 0");
        if (conversionRates[_currencyCode] == 0) {
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    //将货币转为eth,作用于tipInCurrency函数中
    function convertToEth(string memory _currencyCode, uint256 _amount) internal view returns (uint256) {
        uint256 rate = conversionRates[_currencyCode];
        require(rate > 0, "Currency not supported");
        return _amount * rate;
    }

    //直接用eth进行tip
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
    }

    //用其他货币tip
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
    }

    //一次性取出
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalTipsReceived = 0;
    }

    //转移收费方
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    // 返回支持的货币
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    // 小费总数量
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 谁address给了tips
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }

    // 返回特定货币
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return conversionRates[_currencyCode];
    }

    // 返回汇率
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        return conversionRates[_currencyCode];
    }

}