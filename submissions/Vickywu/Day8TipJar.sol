//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;  //跟踪谁部署了合约以及谁控制了管理作（例如添加货币或提取小费）
    
    uint256 public totalTipsReceived;  //这个变量告诉我们合约总体上收集了多少 ETH（以 wei 为单位）
    
    // For example, if 1 USD = 0.0005 ETH, then the rate would be 5 * 10^14
    mapping(string => uint256) public conversionRates; //存储从货币代码（如“USD”）到 ETH 的汇率

    mapping(address => uint256) public tipPerPerson; //存储了每个地址在小费中发送了多少 ETH
    string[] public supportedCurrencies;  // List of supported currencies
    mapping(string => uint256) public tipsPerCurrency;  //跟踪了每种货币的小费金额
    
    constructor() {  //在构造函数中使用它来实际预加载一些值并存储合约所有者地址
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
    
    // Add or update a supported currency
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {  //只有部署合约的人才能添加或更新货币汇率
        require(_rateToEth > 0, "Conversion rate must be greater than 0");  //验证费率
        bool currencyExists = false;  //创建一个布尔变量来检查货币是否存在
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {  //使用 bytes(...)然后将这些字节传递给 keccak256() — 的内置加密哈希函数。
                currencyExists = true;
                break;
            }
        }
        if (!currencyExists) {  //如果它是新货币，即 currencyExists 变量保持 false，我们将该货币添加到 supportedCurrencies 列表中
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;  //更新或设置转化率
    }
    
    //将外币金额转换为 ETH convertToEth 函数接受一个货币代码和一个金额，进行数学运算，并返回等效的 ETH 值（以 wei 为单位）
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
        //If you ever want to show human-readable ETH in your frontend, divide the result by 10^18 :
    }
    
    // Send a tip in ETH directly
    function tipInEth() public payable {  //payable 关键字允许函数实际接收 ETH。如果没有它，该函数将拒绝发送的任何以太币。
        require(msg.value > 0, "Tip amount must be greater than 0");  //msg.value 是与函数调用一起发送的 ETH 数量（以 wei 为单位），防止用户发送 0 ETH 小费
        tipPerPerson[msg.sender] += msg.value;  //记录了该特定用户迄今为止在 tipperContributions中的贡献
        totalTipsReceived += msg.value;  //更新了 totalTipsReceived，这是合约曾经收到的所有 ETH 的运行总数
        tipsPerCurrency["ETH"] += msg.value;  //将小费添加到 tipsPerCurrency 中的"ETH" 桶中，因此我们可以将 ETH 小费与美元或其他货币分开跟踪
    }
    
    //给 ETH 以外的东西打赏
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");  //检查msg.value 即随交易发送的实际 ETH）是否与预期金额匹配
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    //提现小费
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;  //检查余额
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractBalance}("");  //将全部余额发送给合约的 owner “所有者”
        require(success, "Transfer failed");
        totalTipsReceived = 0;  //将totalTipsReceived 重置为 0，仅用于簿记。（注意：这不会影响实际的 ETH 余额——已经发送了。
    }
  
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    //将返回所有者添加到合约中的货币代码（如“美元”、“欧元”等）的完整列表
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }
    

    //合约当前持有多少 ETH，包括：所有已发送的提示和任何尚未提取的 ETH
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
   
    //了解给某人多少小费
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }
    

    //以特定货币支付小费的总金额——例如 2000 美元或 15000 日元
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    //只需提供货币代码（如"USD"），您就会得到存储在合约中的当前汇率
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}