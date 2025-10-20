//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    // 定义一个主要管理员
    address public owner;
    // 定义我们收到的所有小费
    uint256 public totalTipsReceived;
    
    // map[USD]=5 * 10^14
    // For example, if 1 USD = 0.0005 ETH, then the rate would be 5 * 10^14
    // 这里的5 * 10^14是自己配置的，如果在一个工程中需要动态变化
    mapping(string => uint256) public conversionRates;
    // 每个用户付的小费
    mapping(address => uint256) public tipPerPerson;
    // 支持的币种列表
    string[] public supportedCurrencies;  // List of supported currencies
    // 每一个币种付的小费
    mapping(string => uint256) public tipsPerCurrency;
    
    // 初始化汇率，一般在工程中需要为部署前输入
    // 增加支持币种，并在币种与ETH转化的map中增加值：conversionRates
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
    
    // Add or update a supported currency
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");
        bool currencyExists = false;
        // 判断输入币种是否已经为支持币种
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                currencyExists = true;
                // 如果已经为支持币种则直接退出循环
                break;
            }
        }
        // 如果不是，则列入列表
        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }
        // 加入转化map
        conversionRates[_currencyCode] = _rateToEth;
    }
    
    // 我感觉这一步不需要单独写一个函数，在这个场景下直接转化好了
    // 其他币种转化为eth的函数
    // code为币种比如USD，amount是价格如1美元
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        // 需要在支持币种的列表中
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        // 定义一个新的变量为ethAmount
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
        // 当前展示的为单位为wei，如果需要为eth则除以10^18
        //If you ever want to show human-readable ETH in your frontend, divide the result by 10^18 :
    }
    
    // Send a tip in ETH directly
    // 直接赏eth币
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    // 赏其他币种
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        // 需要保证存在支持币种中
        // 保证赏的为大于0
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        // 定义一个转化后的eth值，将不同币种的进行转化成ETH
        uint256 ethAmount = convertToEth(_currencyCode, _amount);

        // 实际转出的金额和账面记得数量需要相同
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    // 不需要convertToEth函数的方法
    // function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
    //     require(conversionRates[_currencyCode] > 0, "Currency not supported");
    //     require(_amount > 0, "Amount must be greater than 0");
    //     uint256 ethAmount = _amount * conversionRates[_currencyCode];
    //     require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
    //     tipPerPerson[msg.sender] += msg.value;
    //     totalTipsReceived += msg.value;
    //     tipsPerCurrency[_currencyCode] += _amount;
    // }

    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalTipsReceived = 0;
    }
    // 转管理
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
    // 获取所有支持币种
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }
    
    // 获取当前地址下的余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // 获取打赏用户打赏的金额
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }
    
    // 获取每个币种的收款金额
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    // 获取某币种下的金额
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}

// owner：0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 
// address 1：0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 
// address 2：0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

// Day08
// 1. 部署之后自动录入USD等四个币种
// 2. tipInCurrency是payable的，填入一定的数额和币种之后，需要自己换算再填入账户以太币中心，要不然会报错
// 3. 其他都比较好懂
