// SPDX-license-Identifier:MIT
pragma solidity^0.8.0;

contract TipJar{

    address public owner; //部署合同的人
    mapping(string => uint256) public conversionRates;  //存储货币代码到ETH的汇率
    string[] public supportedCurrencies;  //存储所有的货币代码 like USD, EUR...
    uint256 public totalTipReceived;  //记录总共收集ETH的总额
    mapping(address => uint256) public tipperContributions;  //存储 谁 打赏了 多少小费
    mapping(string => uint256) public tipsPerCurrency; //存储每种货币的数量金额

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner{
        require(_rateToEth > 0, "Conversion rate must be greater than 0.");
        
        // 检查是否有货币代码存储进去了
        bool currencyExists = false;
        for (uint i = 0; i < supportedCurrencies.length; i++){
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;
            }
        }

        // 如果没有存储该货币代码
        if(!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }

        //保存该货币代码对应的汇率
        conversionRates[_currencyCode] = _rateToEth;

    }

    constructor(){
        owner = msg.sender;

        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);
    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns(uint256){
        require(conversionRates[_currencyCode] > 0, "Currency not supported.");

        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    //如果是用ETH给的小费
    function tipInEth() public payable{
        //为什么没有判断语句来判断是否是ETH呢？还是说msg.value直接对应的就是ETH?
        require(msg.value > 0, "Tip amount must be greater than 0.");

        tipperContributions[msg.sender] += msg.value;  //记录该地址的人对应的tips总额
        totalTipReceived += msg.value;  //计算总ETH的总额？value对应的是ETH吗？
        tipsPerCurrency["ETH"] += msg.value;  //记录货币种类为
    }

    //外币小费
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable{
        require(conversionRates[_currencyCode] > 0, "Currency not supported.");
        require(_amount >0, "Amount must be greater than 0.");

        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount.");  //防止前端作弊，确保账目一致，他在前端填的外币金额换算为ETH要能够和真实发送的ETH数量一致

        tipperContributions[msg.sender] += msg.value;
        totalTipReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;

    }

    //提取小费
    function withdrawTips() public onlyOwner{
        uint256 contractBalance = address(this).balance;  //获取合约当前的ETH余额
        require(contractBalance > 0, "No tips to withdraw.");

        (bool success, ) = payable(owner).call{value: contractBalance}("");  //使用.call将全部余额发送给合约的所有者
        require(success, "Transfer failed.");

        totalTipReceived = 0;
    }

    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0), "Invalid address.");
        owner = _newOwner;
    }

    function getSupportedCurrencies() public view returns (string[] memory){
        return supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256){
        return address(this).balance;
    }

    //查询某个打赏的人给了多少tips
    function getTipperContribution(address _tipper) public view returns (uint256){
        return tipperContributions[_tipper];
    }

    //查询某个货种对应获得的小费
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256){
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode) public view returns(uint256){
        require(conversionRates[_currencyCode] > 0, "Currency not supported.");
        return conversionRates[_currencyCode];
    }
    
}
