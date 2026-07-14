//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//TipJar,implementation

address public owner

mapping(string => uint256) public conversionRates;
string[] public supportedCurrencies;
uint256 public totalTipsReceived;
mapping(address => uint256) public tipperContributions;
mapping(string => uint256) public tipsPerCurrency;


modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can perform this action");
    _;
}
//合约如何知道一美元值多少 ETH？我们将使用名为 addCurrency()的函数手动完成。
 function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
    require(_rateToEth > 0, "Conversion rate must be greater than 0");//验证费率

    //check if currency already exists
    bool currencyExists = false;
    for (uint i = 0; i < supportedCurrencies.length; i++){
        if keccak256(bytes(supportedCurrencies[i]) == keccak256(bytes(_currencyCode))){//keccak256，用于比较是否一致，内置加密哈希函数，如果哈希值匹配，则意味着字符串相等，并且我们知道货币已经存在
            currencyExists = true;
            break;
        }
    }
    //add to the list if it's new
    if (!currencyExists) {
        supportedCurrencies.push(_currencyCode);
    }
    //set the conversion rate
    conversionRates[_currencyCode] = _rateToEth;
 }

 constructor() {
    owner = msg.sender;

    addCurrency("USD", 5 * 10**14);//=0.0005 ETH
    addCurrency("EUR", 6 * 10**15);
    addCurrency("JPY", 4 * 10**12);
    addCurrency("GBP", 7 * 10**14);
 }
// 1 ETH = 1,000,000,000,000,000,000 wei = 10^18 wei

//把wei转换为ETH
function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
    require(conversionRates [currencyCode]) > 0, "Currency not supported";

    uint256 ethAmount = _amount * conversionRates[_currencyCode];
    reture ethAmount;
}
addCurrency("USD", 5 * 10**14); //so 1 USD=0.0005 ETH
ethAmount = 2000 * 5 * 10^14 = 1 * 10^18 wei//solidity仅适用于整数

//eth发小费
function tipInEth() public payable {
    require(msg.value > 0, "Tip amount must be greater than 0");
    tipperContributions[msg.sender] += msg.value;
    totalTipsReceived += msg.value;
    tipsPerCurrency["ETH"] += msg.value;
}

//外币小费
function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
    require(conversionRates[_currencyCode] > 0, "Currency not supported");
    require(_amount > 0, "Amount must be greater than 0");
    uint256 ethAmount = convertToEth(_currencyCode, _amount);
    require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
    tipperContributions += msg.value;
    totalTipsReceived += msg.value;
    tipsPerCurrency[_currencyCode] += _amount;
}
//提现小费 
function withdrawTips() public onlyOwner{
    uint256 contractBalance = address(this).balance;//address来提取余额
    require(contractBalance > 0, "No tips to withdraw");
    (bool success, ) = payable(owner).call{value: contractBalance}("");
    require(success, "Transfer failed");
    totalTipsReceived = 0;//重置为 0，仅用于簿记。（注意：这不会影响实际的 ETH 余额——已经发送了。
}

//转让所有权
function transferOwnership(address _newOwner) public onlyOwner {//只有owner能使用这个功能
    require(_newOwner != address(0), "Invalid address");//我们确保新所有者的地址不是零地址
    owner = _newOwner
}

//检查、读取数据等
function getSupportedCurrencies() public view returns (string[] memory){
    return supportedCurrencies;//这将返回所有者添加到合约中的货币代码（如“美元”、“欧元”等）的完整列表。
}

function getContractBalance() public view returns (uint256){
    return address(this).balance;//这告诉您合约当前持有多少 ETH。它包括：- 所有已发送的提示- 任何尚未提取的 ETH
}

function getTipperContribution(address _tipper) public view returens (uint256){
    returen tipperContributions[_tripper];//知道某某给了多少小费
}

function getTipsCurrency(string memory _currencyCode) public view returns (uint256) {
    return tipsPerCurrency[_currencyCode]//以特定货币支付小费的总金额
}

function getConversionRate(sting memory _currencyCode) public view returns (uint256){
    require(conversionRates[_currencyCode] > 0, "Currency not supported");
    return conversionRates[_currencyCode];
}
//by TipJar contract, we can:
//- 处理 ETH 和外币小费
//- 使用不带小数的缩放转换数学
//- 使用 wei 安全工作
//- 使用 `.call()`保护您的提款