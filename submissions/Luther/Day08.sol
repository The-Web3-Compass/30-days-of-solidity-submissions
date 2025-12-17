//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TipJar {
    address public owner;     //定义一个变量，保存“合约拥有者”的地址

    uint256 public totalTipsReceived;     //定义一个数字变量，记录收到的所有小费总额。

    mapping(string => uint256) public conversionRates;     //这是一个映射表,用来保存“每种货币到以太币（ETH）的换算率”。

    mapping(address => uint256) public tipPerPerson;     //记录每个打赏过的人一共打赏了多少（以 wei 计）
    string[] public supportedCurrencies;     //保存支持的货币列表
    mapping(string => uint256)  public tipsPerCurrency;     //记录每种货币收到的小费总额

    constructor() {
        owner = msg.sender;     //把当前部署合约的人的地址（也就是发送这笔部署交易的人）记录为owner
        addCurrency("USD", 5 * 10**14);     //调用合约中的 addCurrency() 函数，添加一种默认货币 “USD”，并设定它的兑换率
        addCurrency("EUR", 6 * 10**14);     //添加欧元（EUR）的汇率
        addCurrency("JPY", 4 * 10**12);     //添加日元（JPY）的汇率
        addCurrency("INR", 5 * 10**14);     //添加印度卢比（INR）的汇率
    }

//定义只有owner才能执行的规则
modifier onlyOwner() {     //定义一个修饰器（modifier），名字叫 onlyOwner
    require(msg.sender == owner, "Only owner can perform this action");     //检查当前调用者是不是 owner。如果不是，就报错，阻止执行。
    _;     //告诉编译器：“在这里插入被修饰的函数的主体内容。”
}

//添加或更新一种货币
function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {     //定义一个函数，用来添加或更新一种货币的汇率,且只有owner能调用它
    require(_rateToEth > 0, "Conversion rate must be greater than 0");     //防止传入非法的汇率，比如 0 或负数
    bool currencyExists = false;     //声明一个布尔变量 currencyExists，初始为 false,这个变量用来记录“这个货币是否已经存在”
    for (uint256 i = 0; i < supportedCurrencies.length; i++) {     //开始一个 for 循环，用来遍历所有已经添加过的货币
        if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){      //判断当前货币是否已经存在于数组中
            currencyExists = true;    //如果找到了同样的货币，就把 currencyExists 设为 true
            break;     //跳出循环，不再继续检查
        }
    }

    if (!currencyExists) {     //如果循环结束后，仍然没有找到同样的货币（currencyExists 仍是 false），那么说明这是一个新的货币，需要添加到数组里
        supportedCurrencies.push(_currencyCode);     //把新货币代码添加进 supportedCurrencies 数组
    }
    conversionRates[_currencyCode] = _rateToEth;     //无论货币是新的还是已存在，都更新它的汇率
}

function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {     //定义一个函数，用来把某种货币的金额转换成等值的 ETH（以 wei 为单位）
    require(conversionRates[_currencyCode] > 0, "Currencynnot supported");     //检查输入的货币是不是支持的货币,如果没有这个货币对应的汇率，就报错
    uint256 ethAmount = _amount * conversionRates[_currencyCode];     //计算换算后的 ETH 金额
    return ethAmount;     //把计算得到的 ETH 金额返回给调用者
    //如果要显示“人类能读懂的 ETH 值”，需要除以 10^18
}

function tipInEth() public payable {     //定义一个函数，用来接收用户直接用 ETH 打赏
    require(msg.value > 0, "Tip amount must be greater than 0");     //确保用户发送的金额大于 0 wei
    tipPerPerson[msg.sender] += msg.value;     //把这次打赏金额加到该用户的累计打赏总额里
    totalTipsReceived += msg.value;     //增加合约记录的“小费总额”
    tipsPerCurrency["ETH"] += msg.value;     //在按货币分类的统计中，给 “ETH” 项增加这次打赏金额
}

function tipInCurrency(string memory _currencyCode, uint256 _amount)  public payable {     //允许用户用非 ETH 货币（例如 USD、EUR）打赏,前端会根据汇率自动计算需要发送多少 ETH
    require(conversionRates[_currencyCode] > 0, "Currency not supported");     //确保该货币存在于支持列表中
    require(_amount > 0, "Amount must be greater than 0");     //防止输入 0 金额
    uint256 ethAmount = convertToEth(_currencyCode, _amount);     //调用前面定义的函数 convertToEth()，计算对应的 ETH 金额
    require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");     //检查用户发送的 ETH 数量和换算结果是否一致
    tipPerPerson[msg.sender] += msg.value;     //记录该用户的打赏总额（以 ETH 计）
    totalTipsReceived += msg.value;     //更新总打赏金额（合约收到的 ETH 总数）
    tipsPerCurrency[_currencyCode] += _amount;     //更新该货币的小费统计（以货币原单位计，例如 USD 总额）
    }

function withdrawTips() public onlyOwner {     //允许合约主人把所有收到的小费提取到自己钱包
    uint256 contractBalance = address(this).balance;     //查询当前合约账户的 ETH 余额
    require(contractBalance > 0, "No tips to withdraw");     //检查余额是否大于 0
    (bool success, ) = payable(owner).call{value: contractBalance}("");     //把所有 ETH 发送给合约拥有者
    require(success, "Transfer Failed");     //确保转账成功。否则交易回滚
    totalTipsReceived = 0;     //把总小费计数清零
}

//允许当前 owner 把合约所有权转给其他人
function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Invalid address");
    owner = _newOwner;
}

//返回所有支持的货币数组
function getSupportedCurrencies() public view returns (string[] memory) {
    return supportedCurrencies;
}

//查看当前合约持有多少 ETH
function getContractBalance() public view returns (uint256) {
    return address(this).balance;
}

//输入一个钱包地址，返回这个人总共打赏了多少
function getTipperContribution(address _tipper) public view returns (uint256) {
    return tipPerPerson[_tipper];
}

//查看某货币累计打赏总额
function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
    return tipsPerCurrency[_currencyCode];
}

//返回指定货币的 ETH 汇率
function getConversionRate(string memory _currencyCode) public view returns (uint256) {
    require(conversionRates[_currencyCode] > 0, "Currency not supported");
    return conversionRates[_currencyCode];
}

}