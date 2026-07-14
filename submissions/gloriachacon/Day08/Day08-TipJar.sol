// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TipJar {
    address public owner;

    uint256 public totalTipsReceived;

    mapping(string => uint256) public conversionRates;
    mapping(address => uint256) public tipperContributions;
    mapping(string => uint256) public tipsPerCurrency;
    string[] public supportedCurrencies;

    constructor() {
        owner = msg.sender;
        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function addCurrency(string memory code, uint256 rateWeiPerUnit) public onlyOwner {
        require(bytes(code).length != 0, "Bad code");
        require(rateWeiPerUnit > 0, "Bad rate");

        bool exists = false;
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(code))) {
                exists = true;
                break;
            }
        }
        if (!exists) supportedCurrencies.push(code);
        conversionRates[code] = rateWeiPerUnit;
    }

    function getConversionRate(string memory code) public view returns (uint256) {
        require(conversionRates[code] > 0, "Unsupported");
        return conversionRates[code];
    }

    function convertToEth(string memory code, uint256 amount) public view returns (uint256) {
        require(conversionRates[code] > 0, "Unsupported");
        require(amount > 0, "Bad amount");
        return conversionRates[code] * amount;
    }

    function tipInEth() public payable {
        require(msg.value > 0, "Zero");
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function tipInCurrency(string memory code, uint256 amount) public payable {
        require(conversionRates[code] > 0, "Unsupported");
        require(amount > 0, "Bad amount");
        uint256 ethAmount = convertToEth(code, amount);
        require(msg.value == ethAmount, "Mismatch");
        tipperContributions[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[code] += amount;
    }

    function withdrawTips() public onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "Empty");
        (bool ok, ) = payable(owner).call{value: bal}("");
        require(ok, "Transfer failed");
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero addr");
        owner = newOwner;
    }

    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTipperContribution(address tipper) public view returns (uint256) {
        return tipperContributions[tipper];
    }
}