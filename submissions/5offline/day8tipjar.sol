//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

//建立一个小费钱包，支持多币种支付
//变量：钱包地址payable 识别币种 rate转换 付费钱包
//目前支持的币种：字符串 mapping 一共收到多少/每个人给了多少小费 收到的tips什么币种



contract TipJar{
    address public owner;
    string[] public supportedCurrencies;
    mapping(string => uint256) conversionRates;
    uint256 public totalTipsreceived;
    mapping(address => uint256) public tipsperperson;
    mapping(string =>uint256) public tipspercurrency;

    modifier onlyowner(){
        require(msg.sender==owner, "only owner can do that.");
        _;

    }
    constructor(){
        owner = msg.sender;
        //owner = msg.sender;给变量赋初始值，而msg.sender == owner，比较两个地址是否一致
        addCurrency("USD", 5*10**14); //1USD=0.0005ETH 1ETH=10^18wei 当前汇率
        addCurrency("EUR", 6*10**14);
        addCurrency("JPY", 4*10**12);
        addCurrency("INR", 7*10**12);//solidity语言中**才代表次方,10^12=10**12
//加入默认货币汇率值
    }

    //加入modifier，确认哪些步骤只有owner可以做
    //固定汇率or当时汇率,现实汇率需要用到另一课程;
    function addCurrency(string memory _currencyCode, uint256 _ratetoeth) public onlyowner{
        require(_ratetoeth>0,"conversion rate must greater than 0.");
        bool currencyExists=false;
        //for指循环，开启一个循环，直到不满足某个条件为止，for (初始语句; 条件语句; 每轮后的更新语句) {循环体
        for (uint i=0;i< supportedCurrencies.length; i++){
            if(keccak256(bytes(supportedCurrencies[i]))==keccak256 (bytes(_currencyCode)) ) {
                currencyExists=true;
                break;
                //keccak256，哈希值算法：不同于加密可逆，是一种不可逆的转换，将某个输入值转化成固定长度且唯一的值
                //string不能直接用来==，因为很复杂，需要用bytes
                //break代表循环被破坏，如果i=1,两个code相等，那么就不会执行i=2，【一旦你在第二个货架上找到了你要的东西，你就说：“够了，我走人”。】   
            }
        }
        //break后从for外面的代码继续，不会进行i++；eg：i=5，5<length=7,i=6,supportedCurrency[6]=eur,如eur=eur，currencyExists=true;
        if(!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }

         conversionRates[_currencyCode]=_ratetoeth;}
      
        //加入货币汇率,ratetoeth;}忘记闭合符号一直报错
        //比较当前货币是否已经存在，存在则结束循环，继续别的操作，不存在则加入code
         function converttoeth(string memory _currencyCode, uint256 _amount)public view returns(uint256){
            
            //转换的不是eth，而是wei，因为solidity无小数
            require(conversionRates[_currencyCode]>0,"currency is not supported.");
            uint256 ethAmount= _amount*conversionRates[_currencyCode];
            return ethAmount;

    }
    function tipineth()public payable {
        require(msg.value>0,"must send more than 0.");
        tipsperperson[msg.sender] +=msg.value;
        totalTipsreceived +=msg.value;
        //给了小费之后体现在账户里，总额和榜一大姐的个人账户里都要体现
        tipspercurrency["ETH"] +=msg.value;
        //用户打进来多少 ETH（以 wei 表示），就把这个数加到 tipspercurrency[“ETH”] 的累计记录中。
        //eth不是固定写法，可以换成currencycode，eur，usd等
    }
    function tipincurrency(string memory _currencyCode, uint256 _amount) public payable{
        require (conversionRates[_currencyCode]>0, "currency is not supported");
        require (_amount>0, "amount must be greater than 0.");
        uint256 ethamount = converttoeth(_currencyCode, _amount);
        //把指定货币代码的钱转化为eth，变成ethamount
        require(msg.value ==ethamount,"sent eth does not match the converted amount.");
        //这行很重要，因为你给出的钱如果不等于eth通过这个函数转换的，就说明转换的不对
        tipsperperson[msg.sender] +=msg.value;
        totalTipsreceived +=msg.value;
        tipspercurrency[_currencyCode] +=msg.value;
        //和上面一样的，因为都是付款出去，要记录钱包里钱的变化

    }
    function withdrawtips() public onlyowner{
        uint256 contractbalance = address(this).balance;
        //把这个合约账户当前拥有的 ETH 数额（单位是 wei）存进 contractbalance 变量中。
        require(contractbalance>0,"contractbalance amount must greater than 0");
        (bool success,) =payable(owner).call{value: contractbalance}("");
        //要“提取”ETH，把钱从合约账户转给 owner, 内联参数语法（inline call options)
        //给 owner 转账 contractbalance wei 的 ETH，不调用任何合约方法，只是裸转账。
        require(success, "transfere failed");
        totalTipsreceived = 0;


    }
    function transferownership(address _newowner) public onlyowner{
        require(_newowner != address(0),"invalid address.");
        owner =_newowner;
    }
    //合同换人继承
    function getsupportedcurrencies()public view returns(string[]memory ){
    return supportedCurrencies;}
    //查看一些数据

    function getcontractbalance()public view returns(uint256){
        return address(this).balance;
    }
    function gettippercontribution(address _tipper)public view returns (uint256){

        return tipsperperson[_tipper];
    }
    function gettipscurrencies(string memory _currencyCode) public view returns(uint256){
        return tipspercurrency[_currencyCode];
    }


}
