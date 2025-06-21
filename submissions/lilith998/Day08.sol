// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiCurrencyTipJar {
    address public immutable owner;
    
    struct Tip {
        address sender;
        uint256 ethAmount;
        string currency;
        uint256 convertedAmount;
        uint256 timestamp;
    }
    
    Tip[] public allTips;
    mapping(string => uint256) public conversionRates; // wei per unit of foreign currency
    
    event NewTip(
        address indexed sender,
        uint256 ethAmount,
        string currency,
        uint256 convertedAmount,
        uint256 timestamp
    );
    event ConversionRateUpdated(string currency, uint256 rate);
    event Withdrawal(uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // Initialize with sample conversion rates (1 ETH = 3000 USD)
        uint256 rateInWeiPerUsd = (1 ether * 10 ** uint256(18)) / 3000;
conversionRates["USD"] = rateInWeiPerUsd;
// or use a ufixed type if available in the version of Solidity being used.303 ETH
    }
    
    // Accept ETH tips directly
    receive() external payable {
        require(msg.value > 0, "Tip must be > 0");
        
        allTips.push(Tip({
            sender: msg.sender,
            ethAmount: msg.value,
            currency: "ETH",
            convertedAmount: msg.value,
            timestamp: block.timestamp
        }));
        
        emit NewTip(
            msg.sender,
            msg.value,
            "ETH",
            msg.value,
            block.timestamp
        );
    }
    
    // Tip with foreign currency conversion
    function tipInCurrency(string calldata currency, uint256 amount) external payable {
        uint256 rate = conversionRates[currency];
        require(rate > 0, "Currency not supported");
        
        uint256 weiEquivalent = amount * rate;
        require(msg.value == weiEquivalent, "Incorrect ETH amount");
        require(amount > 0, "Amount must be > 0");
        
        allTips.push(Tip({
            sender: msg.sender,
            ethAmount: msg.value,
            currency: currency,
            convertedAmount: amount,
            timestamp: block.timestamp
        }));
        
        emit NewTip(
            msg.sender,
            msg.value,
            currency,
            amount,
            block.timestamp
        );
    }
    
    // Owner functions
    function updateConversionRate(string calldata currency, uint256 rate) external onlyOwner {
        require(rate > 0, "Rate must be > 0");
        conversionRates[currency] = rate;
        emit ConversionRateUpdated(currency, rate);
    }
    
    function withdrawTips() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner).transfer(balance);
        emit Withdrawal(balance);
    }
    
    // View functions
    function getTotalTips() external view returns (uint256) {
        return allTips.length;
    }
    
    function getTip(uint256 index) external view returns (
        address sender,
        uint256 ethAmount,
        string memory currency,
        uint256 convertedAmount,
        uint256 timestamp
    ) {
        require(index < allTips.length, "Invalid index");
        Tip storage tip = allTips[index];
        return (
            tip.sender,
            tip.ethAmount,
            tip.currency,
            tip.convertedAmount,
            tip.timestamp
        );
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}