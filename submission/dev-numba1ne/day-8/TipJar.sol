//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnhancedTipJar {
    address public owner;
    
    uint256 public totalTipsReceived;
    uint256 public lastWithdrawalTime;
    uint256 public withdrawalInterval; // Time between scheduled withdrawals in seconds
    
    // For example, if 1 USD = 0.0005 ETH, then the rate would be 5 * 10^14
    mapping(string => uint256) public conversionRates;

    mapping(address => uint256) public tipPerPerson;
    string[] public supportedCurrencies;  // List of supported currencies
    mapping(string => uint256) public tipsPerCurrency;
    
    // Tipper rewards
    struct TipperRank {
        string name;
        uint256 threshold;  // Minimum amount needed to reach this rank
        uint256 discountBps; // Discount in basis points (100 = 1%)
    }
    
    TipperRank[] public tipperRanks;
    mapping(address => string) public tipperCustomMessages; // Custom thank you messages for top tippers
    
    // Events
    event TipReceived(address indexed tipper, uint256 amount, string currency);
    event CurrencyAdded(string currencyCode, uint256 conversionRate);
    event TipsWithdrawn(address indexed owner, uint256 amount);
    event RankAdded(string name, uint256 threshold, uint256 discountBps);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WithdrawalScheduleUpdated(uint256 newInterval);
    event CustomMessageSet(address indexed tipper, string message);
    
    constructor() {
        owner = msg.sender;
        withdrawalInterval = 30 days; // Default to monthly withdrawals
        lastWithdrawalTime = block.timestamp;
        
        // Add default currencies
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007 ETH
        
        // Add default tipper ranks
        addTipperRank("Bronze Supporter", 0.01 ether, 0); // No discount
        addTipperRank("Silver Supporter", 0.1 ether, 100); // 1% discount
        addTipperRank("Gold Supporter", 0.5 ether, 300); // 3% discount
        addTipperRank("Platinum Supporter", 1 ether, 500); // 5% discount
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    // Add or update a supported currency
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
        emit CurrencyAdded(_currencyCode, _rateToEth);
    }
    
    // Add a new tipper rank
    function addTipperRank(string memory _name, uint256 _threshold, uint256 _discountBps) public onlyOwner {
        require(_discountBps <= 1000, "Discount cannot exceed 10%"); // Max 10% discount
        tipperRanks.push(TipperRank({
            name: _name,
            threshold: _threshold,
            discountBps: _discountBps
        }));
        emit RankAdded(_name, _threshold, _discountBps);
    }
    
    // Set withdrawal schedule
    function setWithdrawalInterval(uint256 _intervalInSeconds) public onlyOwner {
        require(_intervalInSeconds >= 1 days, "Interval must be at least 1 day");
        withdrawalInterval = _intervalInSeconds;
        emit WithdrawalScheduleUpdated(_intervalInSeconds);
    }
    
    // Allow top tippers to set a custom message
    function setCustomMessage(string memory _message) public {
        require(getTipperRank(msg.sender) >= 2, "Must be at least Silver rank to set message"); // At least Silver
        require(bytes(_message).length <= 200, "Message too long");
        tipperCustomMessages[msg.sender] = _message;
        emit CustomMessageSet(msg.sender, _message);
    }
    
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
    }
    
    // Calculate discount based on tipper's rank
    function calculateDiscount(address _tipper, uint256 _amount) public view returns (uint256) {
        uint256 rank = getTipperRank(_tipper);
        if (rank == 0) return _amount; // No discount for lowest rank
        
        uint256 discountBps = tipperRanks[rank].discountBps;
        uint256 discount = (_amount * discountBps) / 10000;
        return _amount - discount;
    }
    
    // Get tipper's current rank index (0-based)
    function getTipperRank(address _tipper) public view returns (uint256) {
        uint256 totalTipped = tipPerPerson[_tipper];
        uint256 rank = 0;
        
        for (uint i = 1; i < tipperRanks.length; i++) {
            if (totalTipped >= tipperRanks[i].threshold) {
                rank = i;
            } else {
                break;
            }
        }
        
        return rank;
    }
    
    // Get tipper's rank name
    function getTipperRankName(address _tipper) public view returns (string memory) {
        uint256 rank = getTipperRank(_tipper);
        return tipperRanks[rank].name;
    }
    
    // Send a tip in ETH directly
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        uint256 effectiveAmount = msg.value;
        tipPerPerson[msg.sender] += effectiveAmount;
        totalTipsReceived += effectiveAmount;
        tipsPerCurrency["ETH"] += effectiveAmount;
        
        emit TipReceived(msg.sender, effectiveAmount, "ETH");
    }
    
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        uint256 discountedAmount = calculateDiscount(msg.sender, ethAmount);
        
        require(msg.value >= discountedAmount, "Sent ETH doesn't match the converted amount");
        
        // Use actual sent amount to track contributions
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
        
        emit TipReceived(msg.sender, msg.value, _currencyCode);
    }

    // Standard withdrawal
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        
        lastWithdrawalTime = block.timestamp;
        emit TipsWithdrawn(owner, contractBalance);
    }
    
    // Scheduled withdrawal - can only be called after interval has passed
    function scheduledWithdrawal() public onlyOwner {
        require(block.timestamp >= lastWithdrawalTime + withdrawalInterval, "Withdrawal interval has not passed");
        withdrawTips();
    }
    
    // Check if scheduled withdrawal is available
    function canWithdrawScheduled() public view returns (bool) {
        return block.timestamp >= lastWithdrawalTime + withdrawalInterval;
    }
    
    // Time remaining until next scheduled withdrawal
    function timeUntilNextWithdrawal() public view returns (uint256) {
        uint256 nextWithdrawalTime = lastWithdrawalTime + withdrawalInterval;
        if (block.timestamp >= nextWithdrawalTime) {
            return 0;
        }
        return nextWithdrawalTime - block.timestamp;
    }
  
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }
    
    // Get all tipper ranks info
    function getAllRanks() public view returns (string[] memory names, uint256[] memory thresholds, uint256[] memory discounts) {
        uint256 length = tipperRanks.length;
        names = new string[](length);
        thresholds = new uint256[](length);
        discounts = new uint256[](length);
        
        for (uint i = 0; i < length; i++) {
            names[i] = tipperRanks[i].name;
            thresholds[i] = tipperRanks[i].threshold;
            discounts[i] = tipperRanks[i].discountBps;
        }
        
        return (names, thresholds, discounts);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }
    
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
    
    function getTipperCustomMessage(address _tipper) public view returns (string memory) {
        return tipperCustomMessages[_tipper];
    }
    
    // Get next withdrawal date in Unix timestamp
    function getNextWithdrawalTime() public view returns (uint256) {
        return lastWithdrawalTime + withdrawalInterval;
    }
}
