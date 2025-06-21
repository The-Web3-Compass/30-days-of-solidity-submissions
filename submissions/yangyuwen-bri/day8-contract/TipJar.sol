//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract TipJar{
    //支持的货币、转换率、小费总额、按地址、货币类型统计小费
    address public owner;
    string[] public supportedCurrencies;
    mapping(string => uint256) conversionRates;
    uint256 public totalTipsReceived;
    mapping(address => uint256) public tipsPerPerson;
    mapping(string => uint256) public tipsPerCurrency;

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can perform this action.");
        _;
    }

    //所有货币计算都在链上以 wei 为单位进行
    constructor(){
        owner = msg.sender;
            addCurrency("USD", 5 * 10**14);   //ETH = 10^18 wei
            addCurrency("EUR", 6 * 10**14);
            addCurrency("JPY", 4 * 10**12);
            addCurrency("GBP", 7 * 10**14);
    }

    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner{
        
        require(_rateToEth > 0, "conversation rate must greater than 0.");
        bool currencyExist = false;

        for (uint256 i = 0; i < supportedCurrencies.length; i++){

            if(keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExist = true;
                break;
            }

            if(!currencyExist){
                supportedCurrencies.push(_currencyCode);
            }

            conversionRates[_currencyCode] = _rateToEth;
        }

    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns(uint256){
        require(conversionRates[_currencyCode] > 0, "currency is not supported.");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    function tipInEth() public payable{
        require(msg.value > 0,"tip amount must be greater than 0.");

        tipsPerPerson[msg.sender] += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
        totalTipsReceived += msg.value;

    }

    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable{
        require(conversionRates[_currencyCode] > 0, "currency is not supported.");

        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        
        tipsPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    function tipsWithdraw() public onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, "no tips to withdraw");

        (bool success,) = payable(owner).call{value:balance}("");
        require(success, "withdraw failed.");

        totalTipsReceived = 0;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        
    }

    function getSupportedCurrencies() public view returns (string[] memory) {
    return supportedCurrencies;
    }


}