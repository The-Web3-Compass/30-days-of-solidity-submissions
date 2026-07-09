// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 如何处理现实生活中的货币，如何转换货币呢？
/*
    1. 如何处理ETH 和 wei
    2. 为什么 Solidity 不支持小数
    3. 如何安全地进行转换数学
    4. 以及如何确保用户发送正确数量的 ETH
*/
contract TipJar{
    address public owner;//所有者
    
    mapping( string =>  uint256) Rate;//存储汇率矩阵
    string[] public supportedTokens = ["ETH"];
    uint256 public tipAmount;//合约余额
    
    //有点点问题
    mapping( address => uint256) public tips;//存储用户打赏金额
    
    mapping ( string =>  uint256) public balanceOf;//存储用户不同币种打赏总额
    
    
    

    constructor(){
        owner = msg.sender;//部署合约的人将成为合约所有者

        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Not owner");
        _; // 这将是函数体
    }

    // 转移所有权
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner!=address(0),"Invaild address!");
        owner = _newOwner;
    }

    // 添加币种
    function addCurrency(string memory _currencyCode, uint256 _rateToETH) public onlyOwner{
        require(_rateToETH > 0,"rate must be greater than zero!");
        //是否已经存在该币种
        bool currencyExists = false;
        for(uint i = 0; i < supportedTokens.length; i++){
            if(keccak256(bytes(supportedTokens[i]))==keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;//跳出循环
            }
        }
        require(!currencyExists,"Currency already exists!");
        supportedTokens.push(_currencyCode);
        Rate[_currencyCode] = _rateToETH;
    }

    // 查看支持币种
    function getSupportedCurrencies() public view returns (string[] memory){
        return supportedTokens;
    }

    // 查看合约余额
    function getContractBalance() public view returns(uint256){
        return tipAmount;
    }

    // 查看个人贡献
    function getTipperContribution(address _user) public view returns (uint256){
        return tips[_user];
    }

    // 查看某币种总额（什么意思？）
    function getTipsInCurrency(string memory _token) public view returns (uint256){
        //这个在哪里存储？需要专门找东西存吗？
        return balanceOf[_token];
    }

    // 查看合约汇率
    function getConversionRate(string memory _to) public view returns (uint256){
        return Rate[_to];       
    }

    //直接打赏以太币
    function tipInEth() public payable{
        require(msg.value > 0, "Insufficient ETH!");//本来转账时就已经判断了吧，好像不需要写     
        tipAmount += msg.value;
        tips[msg.sender] += msg.value;
        balanceOf["ETH"] += msg.value;
    } 

    // 按照法币打赏
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable{
        //检查是否在被允许的币种以内,在添加的时候就已经被确认存在了
        require(Rate[_currencyCode] > 0, "Currency not supported");
        // 打赏金额不为0
        require(_amount>0,"amount must be greater than zero");

        uint256 _total = convertToEth(_currencyCode, _amount);
        // 如果接受币种的金额不对，将打赏失败
        require(msg.value == _total, "Insufficient ETH!");
        tipAmount += msg.value;
        balanceOf[_currencyCode] += msg.value;
        tips[msg.sender] += msg.value;

    }

    // 换算金额
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256){
        // 如果给的不是以太币呢？
        // 如果给的法币不在允许的范围内呢？
        require(Rate[_currencyCode] > 0, "Currency not supported");
        uint256 convertTotal = Rate[_currencyCode]*_amount;
        return convertTotal;
    }

    // 提取打赏,由于存在合约被转让，那么转让后是否这个原合约者要把钱提走。假设他没提走
    function withdrawTip(uint256 _amount) public onlyOwner{
        // 判断提取金额是否小于打赏
        // 用transfer转账，别人打赏和我提取并不冲突啊
        //require(tipAmount >= _amount, "Insufficient balance");
        uint256 contractBalance = address(this).balance;
        require(contractBalance>_amount,"No tips tp withdraw!");

        tips[msg.sender] -= _amount;
        (bool success, ) = payable(owner).call{value: _amount}("");
        require(success,"Transfer failed!");
    
    }

}