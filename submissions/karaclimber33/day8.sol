//SPDX-License-Identifier:MIT 
pragma solidity ^0.8.0;

//调用函数
contract TipJar{
    address public owner;

    uint256 totalTipsReceived;

    mapping(string=>uint256)public conversionRates;//转换率
    mapping(address=>uint256)public tipsPerPerson;//每个用户分别打赏多少
    mapping(string=>uint256)public tipsPerCurrency;//每种货币打赏了多少
    string[] public supportedCurrencies;//支持的货币种类


    //构造函数初始化合约
    constructor(){
        owner=msg.sender;
        //addcurrencies
         addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007ETH ETH
    }
    
    //标识符 小警察
    modifier onlyOwner{
        require(msg.sender==owner,"you are not the owner");
        _;

    }

    //添加或者升级储存的货币利率
    function addCurrency(string memory _currency,uint256 _rate)public onlyOwner{
        require(_rate>0,"Conversion rate must be greater than 0");
        bool currencyExists =false;
        //直接这样不就行了：require(conversionRates[_currencyCode]>0,"currency not supported");
        for(uint i=0;i<supportedCurrencies.length;i++){
            if(keccak256(bytes(supportedCurrencies[i]))==keccak256(bytes(_currency))){
            currencyExists =true;
            break;   
            }
         }
        if(!currencyExists){
            supportedCurrencies.push(_currency);  
        }    
        conversionRates[_currency]=_rate;
    }

    //通通转换为ETH

    function convertToETH(string memory _currencyCode,uint256 _amount)public view returns(uint256){
        require(conversionRates[_currencyCode]>0,"currency not supported");
        uint256 ethAmount=_amount*conversionRates[_currencyCode];
        return ethAmount;
    }
    
    //ETH打赏
    function tipInEth() public payable{
        require(msg.value>0,"Tip must be greater than 0");
        totalTipsReceived +=msg.value;//总金额增加
        tipsPerPerson[msg.sender]+=msg.value;//个人打赏累计
        tipsPerCurrency["ETH"]+=msg.value;//货币打赏累计

    }

    //其他货币打赏
    function tipsIncurrency(string memory _currencyCode,uint256 _amount)public payable{
        require(conversionRates[_currencyCode]>0,"currency not supported");//检查货币是否支持
        require(_amount>0,"Tip must be greater than 0.");
        uint256 ethAmount=convertToETH(_currencyCode, _amount);
        //提问：msg.value是会自动把其他货币转换为ETH形式的吗,那计算其他货币有什么必要呢
        require(ethAmount==msg.value,"ETH amount does not match the expected value");
        totalTipsReceived+=msg.value;
        tipsPerPerson[msg.sender]+=msg.value;
        tipsPerCurrency[_currencyCode]+=msg.value;
    }

    //提现(call的练习
    function withdrawTips()public onlyOwner{
        uint256 contractBalance=address(this).balance;
        require(contractBalance>0,"No tips to withdraw");
        (bool success,)=payable(owner).call{value:contractBalance}("");//call的用法
        require(success,"Withdraw failed");
        //提问既然有contractBalance=address(this).balance这种方法可以知道账户余额为什么还需要totalTipsReceived这个变量来记录？
        totalTipsReceived=0;
    }

    //换主理人
    function transferOwnership(address _newOwner)public onlyOwner{
        //安全检查（新主理人地址不为空
        require(_newOwner!=address(0),"Invalid address");
        owner=_newOwner;
    }
    
    //查看支持货币列表
    function getSupportedCurrencies()public view returns(string[] memory){
            return supportedCurrencies;

    }

    //查看合约余额
    function getContractBalance()public view returns(uint256){
        return address(this).balance;
    }

    //查看个人的贡献度
    function getTipsContribution(address _user)public view returns(uint256){
        return tipsPerPerson[_user];
    }
    //查看每种货币打赏量
    function getTipsInCurrency(string memory _currency)public view returns(uint256){
        return tipsPerCurrency[_currency];
    }
    //查看货币利率
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }

}