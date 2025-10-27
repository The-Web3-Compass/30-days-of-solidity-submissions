// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import @chainlink to get conversion price feed
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TipJar {
    address public owner;
    
    uint256 public totalTipReceived;
    
    mapping(string => uint256) public conversionRates;
    mapping(address => uint256) public tipByUser;
    string[] public supportedCurrencyList;
    mapping(string => uint256) public tipByCurrency;

    address[] public fxRateList = [0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910, //EUR to USD
                                    0x91FAB41F5f3bE955963a986366edAcff1aaeaa83, //GBP to USD
                                    0x8A6af2B75F23831ADc973ce6288e5329F63D86c6 //JPY to USD
                                    ];
    
    constructor() {
        owner = msg.sender;
        addCurrency("USD", address(0));
        addCurrency("EUR", fxRateList[0]);
        addCurrency("GBP", fxRateList[1]);
        addCurrency("JPY", fxRateList[2]);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function convertToETH(string memory currency, address fxRateLookup) public view returns (uint256) {
        (, int256 p1,,,) = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).latestRoundData(); // get the rate from ETH to USD
        require(p1 > 0, "Failed to obtain exchange rate");
        
        uint256 p2 = 1e8;
        if (keccak256(bytes(currency)) != keccak256(bytes("USD"))) {
            (, int256 pTemp,,,) = AggregatorV3Interface(fxRateLookup).latestRoundData(); // get the rate from certain currency to USD
            require(pTemp > 0, "Failed to obtain exchange rate.");
            p2 = uint256(pTemp);
        }

        uint256 ethPerUnit = (1e18 * p2) / uint256(p1);
        return ethPerUnit;
    }

    function addCurrency(string memory currency, address fxRateLookup) public onlyOwner {
        //require(fxRateLookup != address(0), "Invalid conversion rate lookup address.");
        if (conversionRates[currency] == 0) {
            supportedCurrencyList.push(currency);
        }
        conversionRates[currency] = convertToETH(currency, fxRateLookup);
    }



    function addTipByETH() public payable {
        require(msg.value > 0, "Invalid tip amount.");
        
        totalTipReceived += msg.value;
        tipByUser[msg.sender] += msg.value;
        tipByCurrency["ETH"] += msg.value;
    }

    function addTipByCurrency(string memory currency, uint256 amount) public payable{
            require(amount > 0, "Invalid tip amount.");
            require(conversionRates[currency] > 0, "Currency not supported.");
            
            uint256 ethAmount = amount * conversionRates[currency];
            require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");

            totalTipReceived += ethAmount;
            tipByUser[msg.sender] += amount;
            tipByCurrency[currency] += amount;
    }

    function withdrawTip(uint amount) public onlyOwner{
        require(amount > 0, "Invalid withdrawal amount.");
        require(amount < address(this).balance, "Amount should not exceed the jar balance.");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed.");
    }


     function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }


    function getTotalTipReceived() public view returns (uint256) {
        return totalTipReceived;
    }

    function getSupportedCurrencyList() public view returns (string[] memory) {
        return supportedCurrencyList;
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
   
    function getTipByUser(address user) public view returns (uint256) {
        return tipByUser[user];
    }

    function getTipByCurrency(string memory currency) public view returns (uint256) {
        return tipByCurrency[currency];
    }

    function getConversionRate(string memory currency) public view returns (uint256) {
        require(conversionRates[currency] > 0, "Currency not supported.");
        return conversionRates[currency];
    }



}