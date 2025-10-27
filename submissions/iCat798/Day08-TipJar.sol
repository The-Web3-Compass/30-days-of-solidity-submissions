//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;              // 跟踪谁部署了合约以及谁控制了管理作业
    
    uint256 public totalTipsReceived;  // 合约总体上收集了多少ETH(wei)
    
    // 存储从货币代码到ETH的汇率 For example, if 1 USD = 0.0005 ETH, then the rate would be 5 * 10^14
    mapping(string => uint256) public conversionRates;  

    mapping(address => uint256) public tipPerPerson;   // 每个地址在小费中发送了多少ETH
    string[] public supportedCurrencies;               // 动态数组，跟踪添加的所有货币代码，便于后续循环访问 List of supported currencies
    mapping(string => uint256) public tipsPerCurrency; // 跟踪每种货币的小费金额
    
    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH ,以wei为单位，转化率按10^18,无小数，没有舍入错误
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007ETH ETH
    }
    

    // 修饰符，确保只有合约的所有者才能调用某些函数
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    // 设置货币转换，Add or update a supported currency
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");
        bool currencyExists = false;   // 创建布尔变量→检查货币是否存在

        // 避免两次添加相同货币：循环浏览已添加的货币列表
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) { // 统一格式再比较
                currencyExists = true;
                break;
            }
        }

        // 存储货币和汇率 add to list if it's new
        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }
    
    // 将外币转化为ETH
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
        //If you ever want to show human-readable ETH in your frontend, divide the result by 10^18 :
    }
    
    // 用ETH发送小费
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }
    
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;       // 获取合约当前ETH余额
        require(contractBalance > 0, "No tips to withdraw");   // 无可提取，停止改功能
        (bool success, ) = payable(owner).call{value: contractBalance}("");   // 安全灵活发送ETH
        require(success, "Transfer failed");     // 成功即返回success
        totalTipsReceived = 0;                   // 重置计数，仅用于簿记，不影响实际ETH余额
    }
  
    // 转让所有权
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    
    // 查询所有者添加到合约中的货币代码
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }
    
    // 查询合约当前持有ETH数量（wei）
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // 查询某人给了多少小费（wei）→建立排行榜等
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }
    
    // 以特定货币支付小费的总额
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }
    
    // 检查货币代码在合约中的当前汇率
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}