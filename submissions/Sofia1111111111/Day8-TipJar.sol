// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract TipJar{
    //声明变量
    address public owner;
    string[] public supportedCurrencies; //可支持的货币列表
    uint256 public totalTipsReceived; //收到的小费总额
    mapping(string => uint256) public conversionRate; //搜索特定货币的汇率
    //例如，1USD = 0.0005ETH, 汇率为 5*10^14
    mapping(string => uint256) public tipsPerCurrency; //搜索特定外币的总额
    mapping(address => uint256) public tipPerPerson; //搜索特定人员的小费总额

    //初始化：指定管理者，加入一些支持货币
    constructor() {
        owner = msg.sender;
        //使用直接调用函数传参的方式添加
        addCurrency("USD",5*10**14); // 1USD = 0.0005ETH
        addCurrency("EUR",5*10**14); // 1EUR = 0.0006ETH
        addCurrency("JPY",5*10**14); // 1JPY = 0.000004ETH
        addCurrency("INR",5*10**14); // 1INR = 0.000007ETH
    }

    //设置管理者权限
    modifier onlyOwner() {
        require(msg.sender == owner,"Only owner can perform this action");
        _;
    }

    //添加支持货币和更新货币汇率
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner{
        require(_rateToEth > 0,"Conversion rate must be greater than 0"); //汇率必须大于零
        bool currencyExists = false; //用于判断所添加货币是否已存在列表，初始值是false
        //使用for循环遍历货币列表一一查询对比
        for (uint i = 0; i < supportedCurrencies.length; i++){ //从索引值0开始查起，一直到列表最终长度，查完一个索引值＋1
            //使用if语句设置已存在的判断标准来中止遍历
            if(keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {//solidity不支持字符串直接比对，且keccak256只接受字节类型
                currencyExists = true; //存在则更改bool状态
                break; //退出循环
            }
        }
        //进入下一个判断逻辑：取值若为false（货币不存在）则继续执行
        
        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode); //将输入的货币添加到列表
        }
        //不管新添加的还是已存在的货币都可以更新汇率
        conversionRate[_currencyCode] = _rateToEth;    
    }

    //计算外币转换成以太币的金额并返回
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRate[_currencyCode]> 0,"Currency not supported");
        uint256 ethAmount = _amount * conversionRate[_currencyCode];
        return ethAmount;
    }
    
    //用户使用以太币直接转账，汇给当前合约地址
    function tioInEth() public payable { //无参数地址输入是转给了当前的合约地址
        require(msg.value > 0,"Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value; //汇款人的账单增加
        totalTipsReceived += msg.value; //收款账单总额增加
        tipsPerCurrency["ETH"] += msg.value ;//以太币收款账单增加
    }
    
    //查看当前合约地址的余额
    function getContractBalance() public view returns (uint) {
    return address(this).balance;
    }

    //用户使用外币转账，汇给当前合约地址
    function tipInCurrncy(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRate[_currencyCode] > 0,"Currency not supported"); //汇率要大于零
        require(_amount > 0,"Amount must be greater than 0"); //金额要大于零
        uint256 ethAmount = convertToEth(_currencyCode, _amount); //调用函数直接计算外币转换成以太币金额
        require(msg.value == ethAmount,"Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value; //汇款人账单增加金额
        totalTipsReceived += msg.value; //收款人账单总额增加
        tipsPerCurrency[_currencyCode] += _amount; //特定货币收款账单增（这里必须用_amount来计数外币的金额，msg.value是以太币的单位计数的）
    }

    //管理者对合约地址中的余额进行提现，转入管理者地址中
    function withDrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance; //命名一个变量来储存合约地址的余额数目
        require(contractBalance > 0,"No tips to withdraw"); //必须有余额才能提现
        (bool success,) = payable(owner).call{value:contractBalance}(""); //使用内置函数call实现转账功能
        require(success,"Transfer failed"); //必须成功转账才能对收款总额清零
        totalTipsReceived = 0;
    }

    //转让管理者
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0),"Invalid address");
        owner = _newOwner;
    }

    //获取支持货币列表
    function getSupportedCurrencies() public view returns(string[] memory) {
        return supportedCurrencies;
    }

    //查看某个消费者的消费金额
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }

    //查看某种外币的金额总数
    function getTipInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    //查看某种外币的汇率
    function getConversionRate(string memory _currencyCode) public view returns(uint256) {
        require(conversionRate[_currencyCode] > 0,"Currency not supported");
        return conversionRate[_currencyCode];
    }

}

















































































































