//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    uint256 public totaltipsreceived;
    mapping(string => uint256) public conversionrates;
    mapping(address => uint256) public tipperperson;
    string[] public supportedcurrencies;
    mapping(string => uint256) public tipspercurrency;

    constructor() {
        owner = msg.sender;
        addcurrency("USD", 5 * 10**14);
        addcurrency("EUR", 6 * 10**14);
        addcurrency("JPY", 4 * 10**12);
        addcurrency("INR", 7 * 10**12);
    }

     modifier onlyowner() {
        require(msg.sender == owner, "only owner can perform this action");
        _;
     }

     function addcurrency(string memory _currencycode, uint256 _ratetoeth) public onlyowner {
        require(_ratetoeth > 0, "conversion rate must be greater than 0");
        bool currencyexists = false;
        for (uint i = 0; i < supportedcurrencies.length; i++) {
            if (keccak256(bytes(supportedcurrencies[i])) == keccak256(bytes(_currencycode))) {
                currencyexists = true;
                break;
            }
        }
        if(!currencyexists) {
            supportedcurrencies.push(_currencycode);
        }
        conversionrates[_currencycode] = _ratetoeth;
     }

     function converttoeth(string memory _currencycode, uint256 _amount) public view returns (uint256) {
        require(conversionrates[_currencycode] > 0, "currency not supported");
        uint256 ethamount = _amount * conversionrates[_currencycode];
        return ethamount;
     }

     function tipineth() public payable {
        require(msg.value > 0, "tip amount must be greater than 0");
        tipperperson[msg.sender] += msg.value;
        totaltipsreceived += msg.value;
        tipspercurrency["ETH"] += msg.value;
     }

     function tipincurrency(string memory _currencycode, uint256 _amount) public payable {
        require(conversionrates[_currencycode] > 0, "currency not supported");
        require(_amount > 0, "amount must be greater than 0");
        uint256 ethamount = converttoeth(_currencycode, _amount);
        require(msg.value == ethamount, "sent eth doesn't match the converted amount");
        tipperperson[msg.sender] += msg.value;
        totaltipsreceived += msg.value;
        tipspercurrency[_currencycode] += _amount;
     }

     function withdrawtips() public onlyowner {
        uint256 contractbalance = address(this).balance;
        require(contractbalance > 0, "no tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractbalance}("");
        require(success, "transfer failed");
        totaltipsreceived = 0;
     }

     function transferownership(address _newowner) public onlyowner {
         require(_newowner != address(0), "invalid address");
         owner = _newowner;
     }

     function getsupportedcurrencies() public view returns (string[] memory) {
         return supportedcurrencies;
     }

     function getcontractbalance() public view returns (uint256) {
         return address(this).balance;
     }

     function gettippercontribution(address _tipper) public view returns (uint256) {
         return tipperperson[_tipper];
     }

     function gettipsincurrency(string memory _currencycode) public view returns (uint256) {
         return tipspercurrency[_currencycode];
     }

     function getconversionrate(string memory _currencycode) public view returns (uint256) {
         require(conversionrates[_currencycode] > 0, "currency not supported");
         return conversionrates[_currencycode];
     }
}
     
   




