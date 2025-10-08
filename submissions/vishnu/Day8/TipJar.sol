// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    mapping(address => uint256) public etherTips;

    mapping(address => mapping(string => uint256)) public foreignTips;

    mapping(string => uint256) public exchangeRates;

    event EtherTipped(address indexed sender, uint256 amount);
    event ForeignTipped(address indexed sender, string currency, uint256 amountUSD);

    constructor() {
       
        exchangeRates["USD"] = 3e14; 
        exchangeRates["EUR"] = 35e13;
    }

    function tipEther() external payable {
        require(msg.value > 0, "Send ETH to tip");
        etherTips[msg.sender] += msg.value;
        emit EtherTipped(msg.sender, msg.value);
    }

    function tipForeign(string memory currency, uint256 amountInCurrency) external {
        require(exchangeRates[currency] > 0, "Unsupported currency");
        foreignTips[msg.sender][currency] += amountInCurrency;
        emit ForeignTipped(msg.sender, currency, amountInCurrency);
    }

    function convertToEther(string memory currency, uint256 amountInCurrency) public view returns (uint256) {
        uint256 rate = exchangeRates[currency];
        require(rate > 0, "Unsupported currency");
        return amountInCurrency * rate;
    }

    function totalTipsInEther(address user) external view returns (uint256 totalWei) {
        totalWei = etherTips[user];
        totalWei += convertToEther("USD", foreignTips[user]["USD"]);
        totalWei += convertToEther("EUR", foreignTips[user]["EUR"]);
    }
}