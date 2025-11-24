// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;

    uint256 public totalTipsReceived;

    // 例如, 如果 1 USD = 0.0005 ETH, 那么转换比率就是 5 * 10^14
    mapping(string => uint256 ) public conversionRates;

    mapping(address => uint256) public tipPerPerson;
    string[] public supportedCurrencies;
    mapping(string => uint256) public tipsPerCurrency;

    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("INR", 7 * 10**12);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // 增加或更新支持的币种
    function addCurrency(string memory _currencyCode, uint256 _rateToEther) public onlyOwner {
        require(_rateToEther > 0, "Conversion rate must be greater than 0");
        bool currencyExists = false;
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                currencyExists = true;
                break;
            }
        }
        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEther;
    }

    // 币种到以太币的转换
    function convertToEther(string memory _currencyCode, uint256 _amount) public view returns(uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount= _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    // 直接使用ETH付小费
    function tipInEther() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    // 使用其他币种付小费
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Tip amount must be greater than 0");
        uint256 ethAmount = convertToEther(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += ethAmount;
        totalTipsReceived += ethAmount;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    // 提取小费
    function withdrawTips() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Transfer failed");
        totalTipsReceived = 0;
    }

    // 转移所有权
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    // 查询支持的币种
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    // 查询合约余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 查询付小费者的贡献
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }

    // 查询币种的小费总额
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }
    
    // 查询币种的转换比率
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}