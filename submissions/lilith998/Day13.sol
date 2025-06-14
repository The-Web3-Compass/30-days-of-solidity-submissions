// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ERC20 token
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenSale {
    // Token details
    IERC20 public token;
    string public tokenName;
    string public tokenSymbol;
    uint8 public tokenDecimals;
    
    // Sale parameters
    address public owner;
    uint256 public tokenPrice; // Price in wei per token (1 token = tokenPrice wei)
    uint256 public tokensSold;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase = 0.01 ether;
    uint256 public maxPurchase = 10 ether;
    
    // Vesting parameters
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliff; // Time until first claim
        uint256 duration; // Total vesting duration
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    bool public vestingEnabled;
    
    // Events
    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event PriceChanged(uint256 newPrice);
    event SaleExtended(uint256 newEndTime);
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount);
    event TokensClaimed(address indexed beneficiary, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    modifier saleActive() {
        require(block.timestamp >= saleStartTime && block.timestamp <= saleEndTime, "Sale not active");
        _;
    }
    
    constructor(
        address _tokenAddress,
        uint256 _tokenPrice,
        uint256 _saleDurationDays
    ) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        tokenPrice = _tokenPrice;
        
        // Set token details
        tokenName = "MyToken";
        tokenSymbol = "MTK";
        tokenDecimals = 18;
        
        // Set sale timing
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + (_saleDurationDays * 1 days);
    }
    
    // Purchase tokens with ETH
    function buyTokens() external payable saleActive {
        require(msg.value >= minPurchase, "Below minimum purchase");
        require(msg.value <= maxPurchase, "Exceeds maximum purchase");
        
        uint256 tokenAmount = (msg.value * 10**tokenDecimals) / tokenPrice;
        require(tokenAmount > 0, "Insufficient ETH for purchase");
        
        // Check contract has enough tokens
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= tokenAmount, "Insufficient tokens in sale");
        
        // Transfer tokens to buyer
        if (vestingEnabled) {
            // Setup vesting schedule
            vestingSchedules[msg.sender] = VestingSchedule({
                totalAmount: tokenAmount,
                claimedAmount: 0,
                startTime: block.timestamp,
                cliff: 30 days, // 1 month cliff
                duration: 180 days // 6 months vesting
            });
            emit VestingScheduleCreated(msg.sender, tokenAmount);
        } else {
            // Immediate transfer
            require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");
        }
        
        tokensSold += tokenAmount;
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }
    
    // Claim vested tokens
    function claimTokens() external {
        require(vestingEnabled, "Vesting not enabled");
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule");
        
        uint256 claimable = calculateVestedAmount(msg.sender) - schedule.claimedAmount;
        require(claimable > 0, "No tokens to claim");
        
        schedule.claimedAmount += claimable;
        require(token.transfer(msg.sender, claimable), "Token transfer failed");
        
        emit TokensClaimed(msg.sender, claimable);
    }
    
    // Calculate vested amount for an address
    function calculateVestedAmount(address beneficiary) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0) return 0;
        
        if (block.timestamp < schedule.startTime + schedule.cliff) {
            return 0; // Before cliff period
        } else if (block.timestamp >= schedule.startTime + schedule.duration) {
            return schedule.totalAmount; // After vesting period
        } else {
            // During vesting period
            uint256 elapsed = block.timestamp - (schedule.startTime + schedule.cliff);
            return (schedule.totalAmount * elapsed) / schedule.duration;
        }
    }
    
    // Owner functions
    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be > 0");
        tokenPrice = newPrice;
        emit PriceChanged(newPrice);
    }
    
    function extendSale(uint256 additionalDays) external onlyOwner {
        saleEndTime += additionalDays * 1 days;
        emit SaleExtended(saleEndTime);
    }
    
    function toggleVesting(bool enabled) external onlyOwner {
        vestingEnabled = enabled;
    }
    
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner).transfer(balance);
    }
    
    function withdrawUnsoldTokens() external onlyOwner {
        require(block.timestamp > saleEndTime, "Sale not ended");
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(token.transfer(owner, balance), "Token transfer failed");
    }
    
    function setPurchaseLimits(uint256 _minPurchase, uint256 _maxPurchase) external onlyOwner {
        require(_minPurchase > 0, "Min purchase must be > 0");
        require(_maxPurchase > _minPurchase, "Max must be > min");
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }
    
    // View functions
    function getSaleStatus() public view returns (string memory) {
        if (block.timestamp < saleStartTime) return "Not started";
        if (block.timestamp > saleEndTime) return "Completed";
        return "Active";
    }
    
    function tokensAvailable() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function ethToTokens(uint256 ethAmount) public view returns (uint256) {
        return (ethAmount * 10**tokenDecimals) / tokenPrice;
    }
    
    function tokensToEth(uint256 tokenAmount) public view returns (uint256) {
        return (tokenAmount * tokenPrice) / 10**tokenDecimals;
    }
    
    function getVestingInfo(address beneficiary) public view returns (
        uint256 totalAmount,
        uint256 claimedAmount,
        uint256 claimableAmount,
        uint256 startTime,
        uint256 cliff,
        uint256 duration
    ) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        return (
            schedule.totalAmount,
            schedule.claimedAmount,
            calculateVestedAmount(beneficiary) - schedule.claimedAmount,
            schedule.startTime,
            schedule.cliff,
            schedule.duration
        );
    }
    
    // Emergency stop function
    function emergencyStop() external onlyOwner {
        saleEndTime = block.timestamp;
    }
}