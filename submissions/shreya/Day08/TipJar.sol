//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    // --- GAS OPTIMIZATION #1: `immutable` ---
    // The owner is set once in the constructor and never changes.
    // `immutable` makes reading this variable much cheaper than a regular state variable.
    address public immutable owner;

    mapping(string => uint256) public conversionRates;

    uint256 public totalTipsReceived;
    mapping(address => uint256) public tipsPerPerson;
    mapping(string => uint256) public tipsPerCurrency;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        addOrUpdateCurrency("USD", 5 * 10**14);
        addOrUpdateCurrency("EUR", 6 * 10**14);
        addOrUpdateCurrency("JPY", 4 * 10**12);
        addOrUpdateCurrency("INR", 7 * 10**12);
    }

    // --- CONVERSION RATE FUNCTION (Part 1: Setting the Rate) ---

    // --- GAS OPTIMIZATION #2: No Loops ---
    function addOrUpdateCurrency(string calldata _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0.");
        conversionRates[_currencyCode] = _rateToEth;
    }

    // --- CONVERSION RATE FUNCTION (Part 2: Calculating the Conversion) ---
    // This function takes a currency and amount and returns the ETH equivalent.
    function convertToEth(
    // --- GAS OPTIMIZATION #3: `calldata` ---
    // Using `calldata` for read-only inputs like this is cheaper than `memory`.
        string calldata _currencyCode,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 rate = conversionRates[_currencyCode];
        require(rate > 0, "This currency is not supported.");
        return _amount * rate;
    }

    function tipInEth() public payable {
        require(msg.value > 0, "Must send more than 0 ETH.");
        tipsPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function tipInCurrency(string calldata _currencyCode, uint256 _amount) public payable {
        require(_amount > 0, "Amount must be greater than zero.");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH does not match the converted amount.");
        
        tipsPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += msg.value;
    }

    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw.");
        
        totalTipsReceived = 0;
        
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Failed to withdraw funds.");
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContributionAmount(address _tipper) public view returns (uint256) {
        return tipsPerPerson[_tipper];
    }
}