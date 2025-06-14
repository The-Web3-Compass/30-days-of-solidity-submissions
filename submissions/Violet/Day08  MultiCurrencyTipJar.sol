// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiCurrencyTipJar {
    address public owner;
    
    // 小费结构
    struct Tip {
        address sender;
        uint256 timestamp;
        string currency;
        uint256 amount;
        uint256 ethValue;
    }
    
    // 状态变量
    Tip[] public tips;
    mapping(string => uint256) public exchangeRates; // 汇率: 1单位外币 = X wei
    mapping(address => uint256) public contributorTotals;
    
    // 事件
    event TipReceived(address indexed sender, string currency, uint256 amount, uint256 ethValue);
    event ExchangeRateUpdated(string currency, uint256 rate);
    event TipsWithdrawn(address indexed owner, uint256 amount);
    
    // 仅所有者修改器
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // 构造函数 - 设置所有者和初始汇率
    constructor() {
        owner = msg.sender;
        // 设置初始汇率 (示例值)
        exchangeRates["USD"] = 0.0005 ether; // 1 USD = 0.0005 ETH
        exchangeRates["EUR"] = 0.0006 ether; // 1 EUR = 0.0006 ETH
    }
    
    // 接收ETH小费（直接发送）
    receive() external payable {
        _recordTip(msg.sender, "ETH", msg.value, msg.value);
    }
    
    // 发送外币小费
    function sendTip(string memory currency, uint256 amount) external payable {
        require(exchangeRates[currency] > 0, "Currency not supported");
        
        uint256 ethValue = amount * exchangeRates[currency];
        require(msg.value >= ethValue, "Insufficient ETH sent");
        
        // 记录小费
        _recordTip(msg.sender, currency, amount, ethValue);
        
        // 返还多余ETH
        if (msg.value > ethValue) {
            payable(msg.sender).transfer(msg.value - ethValue);
        }
    }
    
    // 内部函数：记录小费
    function _recordTip(address sender, string memory currency, uint256 amount, uint256 ethValue) private {
        tips.push(Tip(sender, block.timestamp, currency, amount, ethValue));
        contributorTotals[sender] += ethValue;
        emit TipReceived(sender, currency, amount, ethValue);
    }
    
    // 更新汇率（仅所有者）
    function updateExchangeRate(string memory currency, uint256 rate) external onlyOwner {
        exchangeRates[currency] = rate;
        emit ExchangeRateUpdated(currency, rate);
    }
    
    // 提取小费（仅所有者）
    function withdrawTips() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        
        payable(owner).transfer(balance);
        emit TipsWithdrawn(owner, balance);
    }
    
    // 获取小费总数
    function getTotalTips() external view returns (uint256) {
        return address(this).balance;
    }
    
    // 获取小费记录数量
    function getTipCount() external view returns (uint256) {
        return tips.length;
    }
    
    // 获取支持的货币列表
    function getSupportedCurrencies() external pure returns (string[] memory) {
        string[] memory currencies = new string[](3);
        currencies[0] = "ETH";
        currencies[1] = "USD";
        currencies[2] = "EUR";
        return currencies;
    }
}