// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 用户使用不同的货币发小费
contract TipJar {

    address private owner;
    // 多种货币对ET的汇率
    mapping(string=>uint) private conversionRates;
    // 货币代码列表
    string[] private currencyCodeList;
    // 当前合约收到的所有ETH
    uint private totalETH;
    // 每个地址发送了多少小费
    mapping(address => uint256) public tipperContributions;
    // 每种货币发了多少小费 
    mapping(string => uint256) public tipsPerCurrency;

    constructor(){
        owner = msg.sender;
         addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007ETH ETH
    }

    // 只有管理员可调用的函数
    modifier checkManager(){
        require(owner == msg.sender,unicode"不是管理员，不能操作");
        _;
    }

    /* 
        添加某货币对ETH的汇率

        此处遍历数组进行了字符串的比对，for(uint i = 0 ; i<= list.length ; i++) 
        for中声明i时必须使用 uint
        string 实质上是字节数组，不能直接用 == 比对，需要先转bytes 在获取hash比对是不是同一个字符串
        bytes("fdvbdsf")  将字符串转化为动态字节数组
        keccak256 是EVM支持的原生指令，gas费用最低，比对字符串一般都用它
        break 跳出for循环
    */
    function  addCurrency(string memory _currencyCode, uint _rateToEth) public checkManager{
        require(_rateToEth > 0 ,unicode"汇率数字必须大于0");
        bool checkExit = false;
        for(uint i = 0 ; i < currencyCodeList.length ; i++){
            if(keccak256(bytes(currencyCodeList[i])) == keccak256(bytes(_currencyCode))){
                checkExit = true;
                break;
            }
        }
        if(!checkExit){
            currencyCodeList.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    // 将指定货币转化为ETH
    function coverToETH(string  memory _currencyCode, uint _rateToEth)public view returns (uint){
        require(_rateToEth > 0 ,unicode"汇率数字必须大于0");

        uint ethAmount = _rateToEth * conversionRates[_currencyCode];
        return ethAmount;
    }

    // 本合约接收小费打赏 使用ETH
    function tipUseEth() public payable{
        require(msg.value > 0,unicode"转账ETH数量必须大于0");

        totalETH += msg.value;
        tipperContributions[msg.sender] =  msg.value;
        tipsPerCurrency["ETH"] = msg.value;
    }

    // 使用其他货币进行打赏
    function tipUseOther(string memory _currencyCode, uint _rateToEth) public  payable {
        require(msg.value > 0,unicode"转账ETH数量必须大于0");
        require(_rateToEth > 0 ,unicode"汇率数字必须大于0");
        require(conversionRates[_currencyCode] > 0,unicode"该货币未保存汇率，无法打赏");
       
        uint ethAmount =  coverToETH(_currencyCode,_rateToEth);
        require(ethAmount == msg.value,unicode"转账ETH数量必须等于货币兑换ETH的数量");

        totalETH += ethAmount;
        tipperContributions[msg.sender] +=  ethAmount;
        tipsPerCurrency[_currencyCode] += ethAmount;
    }

    /*
        小费提现到个人钱包
        
        address(this).balance 当前合约账户的余额
        msg.sender.balance    当前调用者的余额
    */
    function withdrawTips() public checkManager {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0 , unicode"合约账户没钱，不能提现");
        (bool success ,) = payable(owner).call{value : contractBalance}("");
        require(success,unicode"提现失败");
        totalETH -= contractBalance;
    }

    // 合约管理者切换
    function changeOwner(address _owner) public checkManager{
        require(_owner != address(0) , unicode"不能是零地址");
        owner = _owner;
    }

    // 查询货币代码列表
    function getCurrencyCodeList() public view returns(string[] memory){
        return currencyCodeList;
    }

    //查询合约账户余额 
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // 查询用户地址对应发过小费总额
    function getAddrAmount(address _addr) public view returns (uint256) {
        return tipperContributions[_addr];
    }

    //查询每种货币累计打赏了多少
    function getTipsPerCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    // 获取指定货币汇率
    function getCurrencyRate(string memory _currencyCode)public view returns (uint){
        require(conversionRates[_currencyCode] > 0 ,unicode"货币汇率不存在");
        return conversionRates[_currencyCode];
    }

}