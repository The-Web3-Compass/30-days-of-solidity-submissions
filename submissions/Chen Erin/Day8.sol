// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    uint256 public totalTipsReceived;

    // 例如：1 USD = 0.0005 ETH => rate = 5 * 10^14
    mapping(string => uint256) public conversionRates;
    mapping(address => uint256) public tipPerPerson;
    string[] public supportedCurrencies;  // 支持的货币列表
    mapping(string => uint256) public tipsPerCurrency;

    // ===== 📜 事件日志 =====
    event Tipped(
        address indexed sender,
        string currency,
        uint256 amount,
        uint256 ethValue,
        uint256 timestamp
    );

    event CurrencyAdded(
        string currency,
        uint256 rateToEth,
        uint256 timestamp
    );

    event Withdrawn(
        address indexed owner,
        uint256 amount,
        uint256 timestamp
    );

    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner,
        uint256 timestamp
    );

    constructor() {
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

    // ===== 💱 货币与汇率 =====
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");
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
        conversionRates[_currencyCode] = _rateToEth;

        emit CurrencyAdded(_currencyCode, _rateToEth, block.timestamp);
    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    // ===== 💰 打赏功能 =====
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");

        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;

        emit Tipped(msg.sender, "ETH", msg.value, msg.value, block.timestamp);
    }

    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match converted amount");

        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;

        emit Tipped(msg.sender, _currencyCode, _amount, msg.value, block.timestamp);
    }

    // ===== 🏦 提现 =====
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");

        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");

        totalTipsReceived = 0;

        emit Withdrawn(owner, contractBalance, block.timestamp);
    }

    // ===== 👑 所有权管理 =====
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(oldOwner, _newOwner, block.timestamp);
    }

    // ===== 🔍 查询函数 =====
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}