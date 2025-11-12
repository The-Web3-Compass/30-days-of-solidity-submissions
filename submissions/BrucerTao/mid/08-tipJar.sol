// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract TipJar {
    address public owner;
    mapping(string => uint256) public conversionRates; //映射货币代码-》eth的汇率
    string[] public supportedCurrencies;  //记录所有的货币代码
    uint256 public totalTipsReceived; //合约收集了多少eth，wei为单位
    mapping(address => uint256) public tipperContrubutions; //每个地址，以小费形式发送eth数量

    mapping(string => uint256) public tipsPerCurrency;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    //设置货币转换,利用预言机chainlink，先手动获取
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");

        bool currencyExists = false;
        for (uint i=0; i < supportedCurrencies.length; i++){
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;
            }

        }

        if(!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }

        conversionRates[_currencyCode] = _rateToEth;
    }

    constructor() {
        owner = msg.sender;

        addCurrency("USD", 5 * 10**14);  // 1ETH = 10^18wei
        addCurrency("EUR", 5 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);

    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "currency not supported");

        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;

    }

    //使用eth发送小费
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");

        tipperContrubutions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;

    }


    // 以外币支付小费
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "amount must be greater than 0");

        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "sent eth doesnot match the convert amount");
        tipperContrubutions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;

    }

    //提取小费
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");

        (bool success,) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");

        totalTipsReceived = 0;

    }

    //转让所有权
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;

    }

    //从合约中获取信息
    //获取支持的货币
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;

    }


    //获取合约余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;

    }

    
    //返回总贡献值
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipperContrubutions[_tipper];

    }


    //返回需要支付的小费
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];

    }

    //检查1eth值多少钱
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];

    }


}