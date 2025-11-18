// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

//Qingchen
contract TipJar{
    //基本信息
    address public owner;
    mapping (string=>uint256)public rates;//汇率
    string[] public sptedCurs; //支持的货币代码
    uint256 public totalTipsReceived; //总小费
    mapping (address=>uint256) public tipperContributions;//每个地址的小费
    mapping (string=>uint256) public tipsPerCurrency;//每种货币的小费

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }

    //增加货币：代码+汇率（手动设置，后用预言机）
    function addCur(string memory _curCode,uint256 _rateToETH)public onlyOwner{
        require(_rateToETH>0,"Conversion rate must be greater than 0");
        
        //判断货币是否存在
        bool curExists=false;
        for(uint i=0;i<sptedCurs.length;i++){
            if(keccak256(bytes(sptedCurs[i]))==keccak256(bytes(_curCode))){
                curExists=true;
                break;
            }
        }

        //不存在则添加
        if(!curExists){
            sptedCurs.push(_curCode);
        }
        rates[_curCode]=_rateToETH;
    }

    constructor(){
        owner = msg.sender;

        addCur("USD", 5 * 10**14);
        addCur("EUR", 6 * 10**14);
        addCur("JPY", 4 * 10**12);
        addCur("GBP", 7 * 10**14);
    }

    //ETH小费
    function tipInEth() public payable {
        require(msg.value>0,"Tip amount must be greater than 0");
        totalTipsReceived+=msg.value;
        tipperContributions[msg.sender]+=msg.value;
        tipsPerCurrency["ETH"]+=msg.value;
    }
    //其他币种小费：有疑问1111
    //辅助函数-转换为Eth
    function convertToEth(string memory _curCode,uint256 _amount) public view  returns (uint256){
        require(rates[_curCode]>0,"Currency not supported");
        // return _amount * rates[_curCode] ;
        uint256 ethAmount = _amount * rates[_curCode] ;
        return ethAmount;
    }
    function tipInCur(string memory _curCode,uint256 _amount) public payable {
        //转换为ETH
        require(rates[_curCode]>0,"Currency not supported");
        require(_amount>0,"Amount must be greater than 0");

        // uint256 ethAmount=msg.value*rates[_curCode]/(10**18);
        uint256 ethAmount=convertToEth(_curCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match converted amount");
        // totalTipsReceived+=ethAmount;
        // tipperContributions[msg.sender]+=ethAmount;
        // tipsPerCurrency["ETH"]+=ethAmount;
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_curCode] += _amount;
        //注意：amount是外币数量;value是wei大小
    }
    //提现
    function withdrawTips() public onlyOwner{
        uint256 contractBalance = address(this).balance; //balance是内置的？
        require(contractBalance > 0, "No tips to withdraw");
        // payable(owner).transfer(contractBalance);
        (bool success, ) =payable(owner).call{value: contractBalance}("");
        require(success, "Failed to send ETH");
        totalTipsReceived=0;//重置为 0，仅用于簿记
    }
    //转让所有权
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner!=address(0),"Invalid address");
        owner=_newOwner;
    }
/*=====实用函数=====*/
//查看
    //货币
    function getSptedCur() public view returns(string[] memory) {
        return sptedCurs;
    }
    //余额
    function getBalance()  public view returns(uint256){
        return address(this).balance;
    }
    //个人打赏
    function getContribution(address _tipper)public view returns(uint256){
        return tipperContributions[_tipper];
    }
    //种类小费
    function getTipsInCur(string memory _curCode)public view returns(uint256){
        return tipsPerCurrency[_curCode];
    }
    //汇率
    function getRates(string memory _curCode)public view returns(uint256){
        //注意是否存在
        require(rates[_curCode]>0,"Currency not supported");
        return rates[_curCode];
    }

  
}