// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Tipjar {
    address public owner;
    uint256 public totalTipsReceived;   //小费总计
    mapping (string =>uint256) public conversionRates;  //货币对应汇率
    mapping (address => uint256) public tipPerperson;// 地址对应支付费用
    string[] public suppertedCurrencies;   //货币种类
    mapping (string => uint256) tipsperCurrency;    //每种货币对应小费总值
    
    constructor (){
        owner =msg.sender;
        addCurrency("USD",5*10**14);
        addCurrency("EUR",6*10**14); //欧元
        addCurrency("JPY",4*10**14);
        addCurrency("INR",7*10**12);
    }
    //测试添加：CNY 600000000000000 (6*10**14)

    modifier onlyOwner() {
        require(msg.sender ==owner,"only owner can perform this action");
        _;
    }
    //添加货币-汇率
    function addCurrency(string memory _currencyCode,uint256 _rate) public onlyOwner{
        require(_rate >0,"rate must be greater than 0");
        bool currencyExists = false;  //布尔变量检查货币是否存在
        //循环遍历-检查货币
        for (uint i =0;i < suppertedCurrencies.length; i++){
            //Solidity 中的字符串是存储在内存中的复杂类型，而不是原始值。
            //*用bytes(...)然后将这些字节传递给keccak256() — 的内置加密哈希函数。
            //*这为我们提供了每个字符串的唯一指纹，我们会比较它们。如果哈希值匹配，则意味着字符串相等
            if(keccak256(bytes(_currencyCode)) == keccak256(bytes(suppertedCurrencies[i]))){
                currencyExists =true;
                break;
            }
        }
        if (!currencyExists){
            suppertedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode]=_rate;
    } 
    //*计算外币转换为ETH
    function convertToEth(string memory _currencyCode,uint256 _amount) public view returns(uint256){
        require (_amount >0 ,"tip amount must be greater than 0");
        require (conversionRates[_currencyCode] >0,"Currency not supported");
        uint256 ethAmount =_amount * conversionRates[_currencyCode];
        return ethAmount;
    }
    //从用户钱包wallet发送到合约，从ETH发送小费
    function tipInEth() public payable {
        require(msg.value >0,"tip amount must be greater than 0");
        tipPerperson[msg.sender] +=msg.value;
        totalTipsReceived += msg.value;
        tipsperCurrency["ETH"] += msg.value;   //ETH的货币种类
    }
    //*给ETH以外的东西打赏
    function tipInCurrency(string memory _currencyCode,uint _amount) public payable{
        require(conversionRates[_currencyCode] >0 ,"currency not supported");
        require(_amount >0,"amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode,_amount);
        require(msg.value ==ethAmount,"sent ETH doesn't match the converted amount");
        totalTipsReceived +=msg.value;
        tipPerperson[msg.sender] +=msg.value;
        tipsperCurrency[_currencyCode] +=_amount;
    }
    //管理员从合约中取出小费
    function withdrawTips()public onlyOwner{
        uint256 contractBalance =address(this).balance; //获取合约当前余额
        require(contractBalance >0,"no tips to withdraw");
        (bool success,) =payable(owner).call{value:contractBalance}("");
        require(success,"transfer failed");
        totalTipsReceived =0; //重置
    }
    //转管理员
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner !=address(0),"invalid address");
        owner =_newOwner;
    }
    //货币种类查询
    function getSuppertedCurrencies() public view returns(string[] memory){
        return suppertedCurrencies;
    }
    //合约金额查询
    function getContractBalance()public view returns(uint256){
        return address(this).balance;
    }
    //查询各地址打赏消费总额
    function getTipperContribution(address _tipper) public view returns(uint256){
        return tipPerperson[_tipper];
    }
    //查询各小费打赏总额
    function gettipsperCurrency(string memory _currencycode) public view returns(uint256){
        return tipsperCurrency[_currencycode];
    }
    //查询货币对应汇率
    function getRates(string memory _currencyCode) public view returns(uint256){
        return conversionRates[_currencyCode];
    }
}

//owner:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4  
//1:0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2  
//2:0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
//3：0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB  
