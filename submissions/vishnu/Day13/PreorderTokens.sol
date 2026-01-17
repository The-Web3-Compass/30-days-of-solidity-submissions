// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PreorderTokens {
    IERC20 public token;

    address payable public wallet;

    address public owner;
    
    uint256 public rate;
    
    uint256 public weiRaised;
    
    uint256 public tokensSold;
    
    enum SaleStage { PreSale, PublicSale, Ended }
    SaleStage public currentStage;
    
    struct SaleConfig {
        uint256 startTime;
        uint256 endTime;
        uint256 minPurchase;      
        uint256 maxPurchase;      
        uint256 tokenCap;         
        uint256 softCap;          
        uint256 hardCap;          
        bool whitelistRequired;
    }
    
    SaleConfig public saleConfig;
    
    mapping(SaleStage => uint256) public stageRates;
    
    mapping(address => uint256) public contributions; 
    mapping(address => uint256) public tokensPurchased;
    mapping(address => bool) public whitelist;
    
    mapping(address => address) public referrals;
    mapping(address => uint256) public referralEarnings;
    uint256 public referralBonus = 500; 
    
    struct BonusTier {
        uint256 minAmount; 
        uint256 bonusRate; 
    }
    
    BonusTier[] public bonusTiers;

    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount,
        uint256 bonusTokens
    );
    
    event RateChanged(uint256 previousRate, uint256 newRate);
    event StageChanged(SaleStage previousStage, SaleStage newStage);
    event WhitelistUpdated(address indexed account, bool status);
    event SaleConfigUpdated();
    event Refund(address indexed beneficiary, uint256 amount);
    event SaleFinalized();
    event ReferralSet(address indexed buyer, address indexed referrer);
    event ReferralPaid(address indexed referrer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "PreorderTokens: caller is not the owner");
        _;
    }
    
    modifier saleActive() {
        require(
            block.timestamp >= saleConfig.startTime && 
            block.timestamp <= saleConfig.endTime &&
            currentStage != SaleStage.Ended,
            "PreorderTokens: sale is not active"
        );
        _;
    }
    
    modifier whitelistCheck() {
        if (saleConfig.whitelistRequired) {
            require(whitelist[msg.sender], "PreorderTokens: address not whitelisted");
        }
        _;
    }
    
    constructor(
        uint256 _rate,
        address payable _wallet,
        IERC20 _token
    ) {
        require(_rate > 0, "PreorderTokens: rate is 0");
        require(_wallet != address(0), "PreorderTokens: wallet is the zero address");
        require(address(_token) != address(0), "PreorderTokens: token is the zero address");
        
        rate = _rate;
        wallet = _wallet;
        token = _token;
        owner = msg.sender;
        currentStage = SaleStage.PreSale;

        saleConfig = SaleConfig({
            startTime: block.timestamp,
            endTime: block.timestamp + 30 days,
            minPurchase: 0.01 ether,
            maxPurchase: 10 ether,
            tokenCap: 1000000 * 10**18, // 1M tokens
            softCap: 100 ether,
            hardCap: 1000 ether,
            whitelistRequired: false
        });
        
        stageRates[SaleStage.PreSale] = _rate * 120 / 100;  
        stageRates[SaleStage.PublicSale] = _rate;           

        bonusTiers.push(BonusTier(1 ether, 500));   
        bonusTiers.push(BonusTier(5 ether, 1000)); 
        bonusTiers.push(BonusTier(10 ether, 1500));
    }
    
    receive() external payable {
        buyTokens(msg.sender, address(0));
    }
    
    function buyTokens(address beneficiary, address referrer) public payable saleActive whitelistCheck {
        require(beneficiary != address(0), "PreorderTokens: beneficiary is the zero address");
        require(msg.value >= saleConfig.minPurchase, "PreorderTokens: amount below minimum purchase");
        require(
            contributions[msg.sender] + msg.value <= saleConfig.maxPurchase,
            "PreorderTokens: amount exceeds maximum purchase per address"
        );
        require(weiRaised + msg.value <= saleConfig.hardCap, "PreorderTokens: hard cap exceeded");
        
        uint256 weiAmount = msg.value;
        
        if (referrer != address(0) && referrals[msg.sender] == address(0) && referrer != msg.sender) {
            referrals[msg.sender] = referrer;
            emit ReferralSet(msg.sender, referrer);
        }
        
        uint256 currentRate = stageRates[currentStage];
        uint256 tokens = weiAmount * currentRate;
        
        uint256 bonusTokens = calculateBonus(weiAmount, tokens);
        uint256 totalTokens = tokens + bonusTokens;
        
        require(
            tokensSold + totalTokens <= saleConfig.tokenCap,
            "PreorderTokens: not enough tokens available"
        );
        
        require(
            token.balanceOf(address(this)) >= totalTokens,
            "PreorderTokens: insufficient token balance in contract"
        );
        
        // Update state
        weiRaised += weiAmount;
        tokensSold += totalTokens;
        contributions[msg.sender] += weiAmount;
        tokensPurchased[beneficiary] += totalTokens;
 
        require(token.transfer(beneficiary, totalTokens), "PreorderTokens: token transfer failed");

        if (referrals[msg.sender] != address(0)) {
            _processReferral(referrals[msg.sender], weiAmount);
        }

        wallet.transfer(weiAmount);
        
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens, bonusTokens);

        if (weiRaised >= saleConfig.hardCap) {
            _finalizeSale();
        }
    }
    
    function calculateBonus(uint256 weiAmount, uint256 baseTokens) public view returns (uint256) {
        uint256 bonusPercentage = 0;
       
        for (uint256 i = 0; i < bonusTiers.length; i++) {
            if (weiAmount >= bonusTiers[i].minAmount) {
                bonusPercentage = bonusTiers[i].bonusRate;
            }
        }
        
        return baseTokens * bonusPercentage / 10000; 
    }

    function _processReferral(address referrer, uint256 weiAmount) internal {
        uint256 referralReward = weiAmount * referralBonus / 10000;
        referralEarnings[referrer] += referralReward;
 
        payable(referrer).transfer(referralReward);
        
        emit ReferralPaid(referrer, referralReward);
    }
    
    function getCurrentRate() public view returns (uint256) {
        return stageRates[currentStage];
    }

    function calculateTokenAmount(uint256 weiAmount) public view returns (uint256 baseTokens, uint256 bonusTokens) {
        uint256 currentRate = getCurrentRate();
        baseTokens = weiAmount * currentRate;
        bonusTokens = calculateBonus(weiAmount, baseTokens);
    }

    function goalReached() public view returns (bool) {
        return weiRaised >= saleConfig.softCap;
    }
    
    function hasClosed() public view returns (bool) {
        return block.timestamp > saleConfig.endTime || currentStage == SaleStage.Ended;
    }

    function getSaleStats() public view returns (
        uint256 totalRaised,
        uint256 totalTokensSold,
        uint256 tokensRemaining,
        uint256 progressPercentage,
        bool softCapReached,
        bool hardCapReached
    ) {
        totalRaised = weiRaised;
        totalTokensSold = tokensSold;
        tokensRemaining = saleConfig.tokenCap - tokensSold;
        progressPercentage = (weiRaised * 100) / saleConfig.hardCap;
        softCapReached = goalReached();
        hardCapReached = weiRaised >= saleConfig.hardCap;
    }
    
    function setRate(uint256 newRate) public onlyOwner {
        require(newRate > 0, "PreorderTokens: rate is 0");
        
        uint256 previousRate = rate;
        rate = newRate;
        stageRates[currentStage] = newRate;
        
        emit RateChanged(previousRate, newRate);
    }

    function setStage(SaleStage newStage) public onlyOwner {
        SaleStage previousStage = currentStage;
        currentStage = newStage;
        
        emit StageChanged(previousStage, newStage);
    }

    function updateSaleConfig(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        uint256 _tokenCap,
        uint256 _softCap,
        uint256 _hardCap,
        bool _whitelistRequired
    ) public onlyOwner {
        require(_endTime > _startTime, "PreorderTokens: end time must be after start time");
        require(_softCap <= _hardCap, "PreorderTokens: soft cap cannot exceed hard cap");
        
        saleConfig.startTime = _startTime;
        saleConfig.endTime = _endTime;
        saleConfig.minPurchase = _minPurchase;
        saleConfig.maxPurchase = _maxPurchase;
        saleConfig.tokenCap = _tokenCap;
        saleConfig.softCap = _softCap;
        saleConfig.hardCap = _hardCap;
        saleConfig.whitelistRequired = _whitelistRequired;
        
        emit SaleConfigUpdated();
    }
    
    function addToWhitelist(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
            emit WhitelistUpdated(addresses[i], true);
        }
    }

    function removeFromWhitelist(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
            emit WhitelistUpdated(addresses[i], false);
        }
    }
    
    function addBonusTier(uint256 minAmount, uint256 bonusRate) public onlyOwner {
        bonusTiers.push(BonusTier(minAmount, bonusRate));
    }
    
    function clearBonusTiers() public onlyOwner {
        delete bonusTiers;
    }
    
    function withdrawUnsoldTokens() public onlyOwner {
        require(hasClosed(), "PreorderTokens: sale has not ended");
        
        uint256 unsoldTokens = token.balanceOf(address(this));
        if (unsoldTokens > 0) {
            require(token.transfer(owner, unsoldTokens), "PreorderTokens: token transfer failed");
        }
    }
    
    function emergencyTokenWithdraw(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner, amount);
    }
    
    function finalizeSale() public onlyOwner {
        _finalizeSale();
    }
    
    function _finalizeSale() internal {
        currentStage = SaleStage.Ended;
        emit SaleFinalized();
    }
    
    function claimRefund() public {
        require(hasClosed(), "PreorderTokens: sale has not ended");
        require(!goalReached(), "PreorderTokens: goal was reached");
        require(contributions[msg.sender] > 0, "PreorderTokens: no contribution to refund");
        
        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        payable(msg.sender).transfer(refundAmount);
        
        emit Refund(msg.sender, refundAmount);
    }
    

    function getPurchaseInfo(address purchaser) public view returns (
        uint256 contributed,
        uint256 purchased,
        address referrer,
        bool isWhitelisted
    ) {
        return (
            contributions[purchaser],
            tokensPurchased[purchaser],
            referrals[purchaser],
            whitelist[purchaser]
        );
    }
}
