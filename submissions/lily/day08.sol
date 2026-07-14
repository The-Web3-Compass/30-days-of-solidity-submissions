// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;    

contract TipJar {
    // 多币种支付合约
    address public owner;
    mapping(string => uint256) public conversionRates;
    string[] public supportedCurrencies;
    uint256 public totalTipsReceived;
    mapping(address => uint256) public tipperContributions;
    mapping(string => uint256) public tipsPerCurrency;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only OWNER can perform this action");
        _;
    }

    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner() {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");
        bool currencyExists = false;
        // 循环币种列表，确保不会重复添加
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                // 不能直接比较，使用 keccak256() 加密哈希函数 比较 字符串字节 bytes(...)
                currencyExists = true;
                break;
            }
        }
        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }
        // 无论哪种方式，我们都会更新或设置转化率：
        conversionRates[_currencyCode] = _rateToEth;
    }

    constructor() {
        owner = msg.sender;

        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);
        // 1 ETH = 1,000,000,000,000,000,000 wei = 10^18 wei
    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    function tipEth() public payable {
        // 直接使用 ETH
        require(msg.value > 0, "Tip amount must be greater than 0");

        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        // 使用其他币种
        require(conversionRates[_currencyCode] > 0, "Currency is not supported");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");

        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;

        tipsPerCurrency[_currencyCode] += _amount;
    }

    function withdrawTips() public onlyOwner() {
        // 撤回小费
        uint256 contractBalance = address(this).balance;  // 有多少能撤回
        require(contractBalance > 0, "No tips to withdraw");

        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");

        totalTipsReceived = 0;
    }

    function transferOwnership(address _newOnwer) public onlyOwner() {
        require(_newOnwer != address(0), "Invalid address");
        owner = _newOnwer;
    }

    // 查看支持哪些货币
    function getSupportedCurrency() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    // 查看余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 查看给了多少小费
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipperContributions[_tipper];
    }

    // 查看特定货币总金额
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode]; // 不需要检查币种吗？没出现的币种默认为0
    }

    // 查看货币转换率
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}