// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

contract SimpleIOUContract{
    address public owner;//所有者
    mapping(string=>uint256) public converstionRates;//货币代码到ETH的汇率映射表
    string[] public supportedCurrencies;// 有映射关系的货币代码
    uint256 public totalTipsReceived;//合约总体上收集了多少ETH，单位wei
    mapping(address=>uint256) public tipperContributions;//每个地址在小费中发送了多少ETH
    mapping(string => uint256) public tipsPerCurrency;//跟踪每种货币的小费用金额，也就是这种货币对应多少ETH

    modifier  onlyOwner(){
        require(msg.sender == owner,"Only owner can perform this action");
        _;
    }

    // 手动添加不同货币对应ETH的汇率
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner{
        require(_rateToEth>0,"Conversion rate must be greater than 0");

        bool currencyExists = false;
        for(uint i=0;i<supportedCurrencies.length;i++){
            if(keccak256(bytes(supportedCurrencies[i]))==keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;
            }
        }

        if(!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }

        converstionRates[_currencyCode]=_rateToEth;
    }

    constructor(){
        owner = msg.sender;

        addCurrency("USD", 5*10**14);
        addCurrency("EUR", 6*10**14);
        addCurrency("JPY", 4*10**12);
        addCurrency("GBP", 7*10**14);
    }

    // 将外币转为ETH
    function convertToEth(string memory _currencyCode,uint256 _amount) public view returns(uint256){
        require(converstionRates[_currencyCode]>0,"Currency not supported");

        uint256 ethAmount = _amount*converstionRates[_currencyCode];
        return ethAmount;
    }

    // 以ETH发送小费
    function tipInEth() public payable {
        // 小费必须大于0
        require(msg.value>0,"Tip amount must be greater than 0");
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    // 以外币发送小费
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(converstionRates[_currencyCode]>0,"currency not supported");
        require(_amount>0,"Amount must be greater than 0");
        uint ethAmount = convertToEth(_currencyCode,_amount);
        require(msg.value==ethAmount,"Sent ETH doesn't match the converted amount");
        tipperContributions[msg.sender]+=msg.value;
        totalTipsReceived+=msg.value;
        tipsPerCurrency[_currencyCode]+=_amount;
    }

    // 提款小费
    function withdrawTips() public onlyOwner{
        uint256 contractBalance = address(this).balance;
        require(contractBalance>0,"No tips to withdraw");
        // 将当前合约所有的金额发送给所有者
        (bool success,)= payable (owner).call{value:contractBalance}("");
        require(success,"Transfer failed");
        totalTipsReceived = 0;
    }

    // 转让所有权
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner!=address(0),"Invalid address");
        owner = _newOwner;
    }

    // 查询所支持的外币
    function getSupportedCurrencies() public view returns (string[] memory){
        return supportedCurrencies;
    }

    //查询当前合约有多少ETH
    function getContractBalance() public view  returns (uint256){
        return  address(this).balance;
    }

    // 查询某个人给了多少小费
    function getTipperContribution(address _tipper)public view returns (uint256){
        return tipperContributions[_tipper];
    }

    //查询特定币支付的小费费用
    function getTipsInCurrency(string memory _currencyCode) public view  returns(uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    // 查询1单元外币值多位wei
    function getConversionRate(string memory _currencyCode)public view returns(uint256){
        require(converstionRates[_currencyCode]>0,"Currency not supported");
        return converstionRates[_currencyCode];
    }

}