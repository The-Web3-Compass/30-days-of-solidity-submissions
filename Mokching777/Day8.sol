// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    uint256 public totalTipsReceived;
    uint256 public minimumTip = 0.001 ether;//优化：避免刷小数额
    
    mapping (string => uint256) public conversionRates;//不同货币（如 USD）兑换成 ETH 的比率
    mapping (address => uint256) public tipPerPerson;//记录每个人打赏了多少 ETH
    string[] public supportedCurrencies;//支持哪些货币
    mapping (string => uint256) public tipsPerCurrency;//每种货币共收到多少打赏（非ETH单位）

    struct Tip{
        address sender;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    Tip[] public tipMessages;

    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("INR", 7 * 10**14);
        addCurrency("CNY", 5 * 10**13);//1 CNY = 0.00005 ETH
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can perform this action.");
        _;
    }

    function addCurrency(string memory _currencyCode,uint256 _rateToEth) public onlyOwner{
        require(_rateToEth > 0,"Conversion rate must be greater than 0.");
        bool currencyExists = false;
        for (uint i = 0;i < supportedCurrencies.length;i++){
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;
            }
        }
        if (!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    function convertToEth(string memory _currencyCode,uint256 _amount) public view returns (uint256){
        require(conversionRates[_currencyCode] > 0,"Currency not supported.");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    function tipInEth() public payable {
        require(msg.value > 0,"Tip amount must be greater than 0.");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    event Tipped(address indexed sender, uint256 amount, string message);

    function tipWithMessage(string memory _message) public payable {
        require(msg.value > 0,"Tip must be greater than 0.");

        Tip memory newTip = Tip({
            sender : msg.sender,
            amount : msg.value,
            message : _message,
            timestamp: block.timestamp
        });

        tipMessages.push(newTip);

        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;

        emit Tipped(msg.sender, msg.value, _message);
    }

    function tipInCurrency(string memory _currencyCode,uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0,"Currency not supported.");
        require(_amount > 0,"Amount must be greater than 0.");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);//系统根据设定的汇率换算 ETH，校验实际发送的金额相符，然后记录为 ETH 存入
        require(msg.value == ethAmount,"Sent ETH doesn't match the converted amount.");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    function withdrawTips() public onlyOwner{
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0,"No tips to withdraw.");
        (bool success, ) = payable (owner).call{value:contractBalance}("");
        require(success,"Transfer failed.");
        totalTipsReceived = 0;
    }

    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0),"Invalid address.");
        owner = _newOwner;
    }

    function getSupportedCurrencies() public view returns (string[] memory){
        return supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256){
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns (uint256){
        return tipPerPerson[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256){
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode) public view returns (uint256){
        require(conversionRates[_currencyCode] > 0,"Currency not supported.");
        return conversionRates[_currencyCode];
    }

    function getAllTipMessages() public view returns (Tip[] memory){
        return tipMessages;
    }
}
