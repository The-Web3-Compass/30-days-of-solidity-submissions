// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar{
    address public owner;//分解管理的信息
    uint256 public totalTipsRecieved;

    mapping (string=>uint256)public conversionrates;//跟踪部署的合约
    mapping (string=>uint256)public tipperperson;

    string[]public supportedcurrencies;//存储货币汇率
    mapping (string=>uint256)public tippercurrency;//存储小费发送数

    function addcurrency(string memory currency,uint256 rate)internal onlyowner{
        conversionrates[currency]=rate;
        supportedcurrencies.push(currency);
    }

    constructor(){
        owner=msg.sender;
        addcurrency ("USD",5*10**14);
        addcurrency ("EUR",6*10**14);
        addcurrency ("JPY",4*10**12);
        addcurrency ("INR",7*10**12);
    }
    modifier onlyowner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }
    function addcurrency(string memory_currencycode, uint256 _ratetoETH)public onlyowner{
        require(_ratetoETH>0,"conversionrates must be greater than 0");

        bool currencyexists=false;
        for (uint i =0;i<supportedcurrencies.length;i++){
            if keccak256(bytes(supportedcurrencies[i])) == keccak256(bytes(_currencycode)){
                currencyexists = true ;
                break ;

            }
        }
        if (!currencyExists){
            supportedcurrencies.push(_currencycode);
        }

        conversionrates[_currencycode]=_ratetoETH;//呜呜呜咋整啊看不懂啥都看不懂
    };
    
    function converttoETH(string memory_code,uint256 _amount)public view returns (uint256){
        require(conversionrates[_currencycode]>0,"Currency not supported");

        uint256 rthAmount=_amount*conversionrates[_currencycode];
        return ethAomunt;//将外币转化为ETH
    }
    function tipinETH()public payable {
        require(msg.value>0,"Tip amount must be greater than 0");

        tippercontribution[msg.sender]+=msg.value;//记录贡献
        totalTipsRecieved+=msg.value;//增加recieve
        tipspercurrency["ETH"]+=msg.value;
    }
    function tipincurrency(string memory_code,uint256 _amount)public payable {
        require(conversionrates[_currencycode]>0,"Currency not supported");
        require(_amount>0,"Amount must be greater than 0");

        uint256 ethAmount = converttoETH(_currencycode, _amount);
        require(msg.value==ethAmount);

        tippeercontributions[msg.sender]+=msg.value;
        totalTipsRecieved +=msg.value;
        tipspercurrency[_currencycode]+=_amount;//给ETH以外的东西打赏
    }
    function withdrawTips()public onlyowner{
        uint256 contractbalance=address(this).balance;//看余额
        require(contractbalance>0,"no tips to withdraw");

        (bool success,)=payable (owner).call{value:contractbalance}("");//把余额发给owner
        require(success,"Transfer failed");

        totalTipsRecieved=0;//归零但不是实际上归零
    }
    function transferownership (_address newOwner)public onlyowner{
        require(_newOwner !=address(0),"Invalid address");
        owner=_newowner;//转移owner
    }
    function getsupportedcurrencies()public view returns (string[]memory){
        return supportedcurrencies;//返回添加的原始货币
    }
    function getcontractbalance()public view returns (uint256){
        return address(this).balance;//合约当前的所有ETH
    }
    function gettippercontribution (address _tipper)public view returns (uint256){
        return tippercontributions[_tipper];//谁给了多少小费
    }
    function gettippsincurrency (string memory _currencycode)public view returns (uint256){
        require(conversionrates[_currenycode]>0);//小费货币的总金额
    }
    function getconverstionrates (string memory _currencycode)public view returns (uint256){
        require(conversionrates[_currencycode]>0,"currency not supported");
        return conversionrates[_currencycode];
    }
}