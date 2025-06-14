//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract TipJar{
    address public Owner;
    string[] public SupportedCurrencies;
    mapping(string => uint256) ConversionRates;
    uint256 public TotalTipsRecieved;
    mapping(address => uint256) public TipsPerPerson;
    mapping(string => uint256) public TipsPerCurrency;

    modifier OnlyOwner(){
        require(msg.sender == Owner, "Only owner can do that");
        _;

    }

    constructor(){
        Owner = msg.sender;
        AddCurrency("USD", 5*10**14 );
        AddCurrency("EUR", 6*10**14 );
        AddCurrency("JPY", 4*10**12 );
        AddCurrency("INR", 7*10**12 );

    }

    function AddCurrency (string memory _CurrencyCode_, uint256 _RateToEth_) public OnlyOwner {
        require(_RateToEth_ > 0, "Conversion rate must be greater than 0");
        bool CurrencyExists = false;
        for (uint256 i = 0; i < SupportedCurrencies.length; i++){
            if(keccak256(bytes(SupportedCurrencies[i])) == keccak256(bytes(_CurrencyCode_))){
                CurrencyExists = true;
                break;
            }
            
        }

        if(!CurrencyExists){
            SupportedCurrencies.push(_CurrencyCode_);

        }
        ConversionRates[_CurrencyCode_] = _RateToEth_;

    }

    function ConvertToEth(string memory _CurrencyCode_, uint256 _amount_) public view returns (uint256) {
        require(ConversionRates[_CurrencyCode_] > 0, "Currency is not supported");
        uint256 EthAmount = _amount_ * ConversionRates[_CurrencyCode_];
        return EthAmount;

    }

    function TipInEth() public payable {
        require(msg.value > 0, "Must send more than 0");
        TipsPerPerson[msg.sender] += msg.value;
        TotalTipsRecieved += msg.value;
        TipsPerCurrency["ETH"] +=msg.value;

    }

    function TipInCurrency(string memory _CurrencyCode_, uint256 _amount_) public payable{
        require(ConversionRates[_CurrencyCode_] > 0, "Currency is not supported");
        require(_amount_ > 0, "Amount must be greater than 0");
        uint256 EthAmount = ConvertToEth(_CurrencyCode_, _amount_);
        require(msg.value == EthAmount, "Sent Eth does not match the converted amount");
        TipsPerPerson[msg.sender] += msg.value;
        TotalTipsRecieved +=msg.value;
        TipsPerCurrency[_CurrencyCode_] += msg.value;

    }

    function WithdrawTips() public OnlyOwner{
        uint256 ContractBalance = address(this).balance;
        require(ContractBalance > 0, "No tips to with draw");
        (bool success,) = payable(Owner).call{value:ContractBalance}("");
        require(success, "Transfer failed");
        TotalTipsRecieved = 0;

    }

    function TransferOwnership(address _NewOwner_) public OnlyOwner{
        require(_NewOwner_ != address(0), "Invalid address");
        Owner = _NewOwner_;

    }

    function GetSupportedCurrencies() public view returns(string[] memory){
        return SupportedCurrencies;

    }

    function GetContractBalance() public view returns(uint256){
        return address(this).balance;

    }

    function GetTipperContribution(address _Tipper_) public view returns(uint256){
        return TipsPerPerson[_Tipper_];
        
    }
}
