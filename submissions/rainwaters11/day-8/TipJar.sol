// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    
    // Currency Tracking
    mapping(string => uint256) public conversionRates;
    string[] public supportedCurrencies;
    
    // Tip Tracking
    uint256 public totalTipsReceived;
    mapping(address => uint256) public tipperContributions;
    mapping(string => uint256) public tipsPerCurrency;

    // EXTENDED CHALLENGE: Goal Tracking Variables
    uint256 public fundingGoal;
    string public goalDescription;
    bool public goalReached;

    // Events
    event TipReceived(address indexed tipper, uint256 amount, string currency);
    event GoalReached(uint256 totalRaised);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        
        // Initial setup for fixed rates (simulating 1 USD = 0.0005 ETH)
        addCurrency("USD", 5 * 10**14);
        addCurrency("EUR", 6 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);
    }

    // --- Admin Functions ---
    
    // String comparison in Solidity requires hashing with keccak256
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");

        bool currencyExists = false;
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                currencyExists = true;
                break;
            }
        }

        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }

        conversionRates[_currencyCode] = _rateToEth;
    }

    // EXTENDED CHALLENGE: Set a funding goal
    function setFundingGoal(uint256 _goalAmountInWei, string memory _description) public onlyOwner {
        fundingGoal = _goalAmountInWei;
        goalDescription = _description;
        goalReached = false;
    }

    // --- Tipping Functions ---

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return _amount * conversionRates[_currencyCode];
    }

    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        _processTip(msg.sender, msg.value, "ETH");
    }

    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");

        tipsPerCurrency[_currencyCode] += _amount;
        _processTip(msg.sender, msg.value, _currencyCode);
    }

    // Internal helper function to avoid duplicating logic
    function _processTip(address tipper, uint256 ethAmount, string memory currency) internal {
        tipperContributions[tipper] += ethAmount;
        totalTipsReceived += ethAmount;
        
        emit TipReceived(tipper, ethAmount, currency);

        // Check if the goal was hit!
        if (fundingGoal > 0 && !goalReached && totalTipsReceived >= fundingGoal) {
            goalReached = true;
            emit GoalReached(totalTipsReceived);
        }
    }

    // --- Withdrawal & Views ---

    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");

        // NOTE: We intentionally do not reset totalTipsReceived here so it continues to reflect all historical tips.

        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
    }

    function getProgressTowardsGoal() public view returns (uint256 percentComplete) {
        if (fundingGoal == 0) return 0;
        if (totalTipsReceived >= fundingGoal) return 100;
        
        // Multiply by 100 first to avoid precision loss in integer division
        return (totalTipsReceived * 100) / fundingGoal;
    }
}
