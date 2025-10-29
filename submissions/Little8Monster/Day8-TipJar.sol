// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//构建TipJar智能合约；多币种打赏与汇率换算、统计与提现
contract TipJar {
    address public owner;
    uint256 public totalTipsReceived;

    // 如果 1 美元 = 0.0005 以太币，那么汇率就是 5 * 10^14
    //此映射存储从货币代码（如“USD”）到 ETH 的汇率
    mapping (string => uint256) public conversionRates;

    //tipPerPerson为变量名，表示“每个人的小费记录"
    mapping (address => uint256) public tipPerPerson;

    //动态数组,帮助我们跟踪我们添加的所有货币代码
    string[] public supportedCurrencies; 
    //跟踪了每种货币的小费金额
    mapping (string => uint256) public tipsPerCurrency;

    constructor() {
        owner = msg.sender;
        // 添加货币
        addCurrency("USD", 5 * 10**14);// 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);// 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007ETH ETH
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    //仅所有者添加或更新币种与其兑ETH 汇率
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth >0, "Conversion rate must be greater than 0");
        
        //确认币种是否已经存在
        bool currencyExists = false;
        //for 循环 + if 判断” 的嵌套结构,for 负责“遍历”，if 负责“判断当前这个是不是目标”
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;
            }
        }
        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    //将法币金额按汇率换算为 Wei（ETH 最小单位）
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256){
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    //直接以 ETH 打赏小费，累计到总额与按币种统计
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] +=msg.value;
        //记录了该特定用户迄今为止在 tipperContributions中的贡献
        totalTipsReceived += msg.value;
        //更新了 totalTipsReceived，这是合约曾经收到的所有 ETH 的运行总数
        tipsPerCurrency["ETH"] += msg.value;
        //将小费添加到 tipsPerCurrency 中的"ETH" 桶中，因此我们可以将 ETH 小费与美元或其他货币分开跟踪
    }
    
    //指定货币给 ETH 以外的东西打赏
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value ==ethAmount, "Sent ETH doesn't match the converted amount");
        //函数检查msg.value 即随交易发送的实际 ETH）是否与预期金额匹配
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    //提现全部小费
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        //this 代表当前合约
        //查看当前合约地址（this）里有多少 ETH，然后把这个数额存到变量 contractBalance里
        require(contractBalance > 0, "No tips to withdraw");
        (bool success,) = payable(owner).call{value: contractBalance}("");
        //把合约里所有的钱（contractBalance）打到 owner 地址上去。”
        //payable(owner)：把 owner 地址转成可接收 ETH 的地址类型；
        //.call{value: contractBalance}("")：执行转账操作
        require(success, "Transfer failed");
        totalTipsReceived = 0;
        //把“记录的小费总额”重置为 0
        }

    //转让所有权
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    //从合约中获取信息
    function getsupportedCurrencies() public view returns (string[] memory){
        return supportedCurrencies;
    }

    //查看合约当前持有多少 ETH
    function getContractBalance() public view returns (uint256){
        return address(this).balance;
    }

    //查看某个人给了多少小费
    function getTipperContribution(address _tipper) public view returns (uint256){
        return tipPerPerson[_tipper];
    }

    //以特定货币支付小费的总金额
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    //提供货币代码,得到存储在合约中的当前汇率
    function getConversionRates(string memory _currencyCode) public view returns (uint256){
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }

}