// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract TipJar{
    address public  owner;
    string[] public supportedCurrencies;
    mapping (string => uint256 )conversionRates;
    uint256 public totalTipsRecieved;
    mapping (address => uint256) public tipsPerPerson;
    mapping (string => uint256) public tipsPerCurrency;

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can do that");
        _;
    }

    constructor(){
        owner = msg.sender;
        addCurrency("USD", 5*10^4 ); //1 USD = 0.0005ETH.   1ETH - 10^18wei
        addCurrency("EUR", 6*10^14 );
        addCurrency("JPY", 4*10^12 );  //1 JPY = 0.000004eth
        addCurrency("INR", 7*10^12 );
    }

    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner{
        require(_rateToEth > 0,"Conversion rate must be greater than zero");
        bool currencyExists = false;
        for (uint256 i = 0; i < supportedCurrencies.length; i++){
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;
            }
        }

        if(!currencyExists){
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns(uint256){
        require(conversionRates[_currencyCode] > 0,"Currency is not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }

    function tipInEth() public payable {
        require(msg.value > 0,"Must send more than 0");
        tipsPerPerson[msg.sender] += msg.value;
        totalTipsRecieved+= msg.value;
        tipsPerCurrency["ETH"]+= msg.value;
    }

    function tipInCurrency(string memory _currencycode, uint256 _amount) public payable {
        require(conversionRates[_currencycode] > 0,"Currency is not supported");
        require(_amount > 0 ,"Amount must be greater than zero");
        uint256 ethAmount = convertToEth(_currencycode, _amount);
        require(msg.value == ethAmount,"Sent ETH does not match the converted amount");
        tipsPerPerson[msg.sender] += msg.value;
        totalTipsRecieved+= msg.value;
        tipsPerCurrency[_currencycode]+= msg.value;

        //2000 USD * 5*10……14 WEI =1*10^18 WEI = 1eth
    }

    function withdrawTips() public onlyOwner{
        uint256 contractBalance = address(this).balance;
        require(contractBalance >0,"No tips to withdraw");
        (bool success,) = payable (owner).call{value:contractBalance}("");
        require(success,"Transfer Failed");
        totalTipsRecieved = 0;
    }

    function transferOwnership(address _newOwner) public  onlyOwner{
        require(_newOwner != address(0),"Invalid address");
        owner = _newOwner;

    }

    function getSupportedCurrencies() public view  returns (string[] memory){
        return supportedCurrencies;
    }

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns(uint256){
        return tipsPerPerson[_tipper];
    }

    function getTipsInCurrency(string memory _currencyCode) public  view returns(uint256){
        return tipsPerCurrency[_currencyCode];
    }


}
