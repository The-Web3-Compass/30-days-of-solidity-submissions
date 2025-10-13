// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PreorderTokens
 * @dev A token pre-sale contract that allows users to buy tokens with Ether
 * 
 * Key Concepts:
 * 1. Token Economics: Managing supply, pricing, and distribution
 * 2. Rate Calculations: Converting Ether to tokens based on exchange rate
 * 3. Sales Management: Tracking purchases and managing pre-sale lifecycle
 */
contract PreorderTokens {
    // Token details
    string public name = "PreOrder Token";
    string public symbol = "POT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    // Sale parameters
    address public owner;
    uint256 public tokenPrice; // Price in wei per token (with 18 decimals)
    uint256 public tokensAvailable;
    uint256 public tokensSold;
    bool public saleActive;
    
    // Sale statistics
    uint256 public totalEtherRaised;
    uint256 public minimumPurchase;
    uint256 public maximumPurchase;
    
    // Mappings
    mapping(address => uint256) public balances;
    mapping(address => uint256) public purchases; // Track individual purchases
    
    // Events
    event TokensPurchased(
        address indexed buyer,
        uint256 etherAmount,
        uint256 tokenAmount,
        uint256 timestamp
    );
    
    event SaleStatusChanged(bool active, uint256 timestamp);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event TokensWithdrawn(address indexed owner, uint256 amount);
    event EtherWithdrawn(address indexed owner, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier saleIsActive() {
        require(saleActive, "Sale is not active");
        _;
    }
    
    /**
     * @dev Constructor to initialize the pre-sale
     * @param _initialSupply Total supply of tokens to create
     * @param _tokenPrice Price per token in wei
     * @param _tokensForSale Number of tokens available for pre-sale
     */
    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _tokensForSale
    ) {
        require(_tokenPrice > 0, "Token price must be greater than 0");
        require(_tokensForSale <= _initialSupply, "Cannot sell more than supply");
        
        owner = msg.sender;
        totalSupply = _initialSupply * 10**decimals;
        tokenPrice = _tokenPrice;
        tokensAvailable = _tokensForSale * 10**decimals;
        
        // Mint all tokens to contract
        balances[address(this)] = totalSupply;
        
        // Set default purchase limits
        minimumPurchase = 0.01 ether; // Minimum 0.01 ETH
        maximumPurchase = 10 ether;   // Maximum 10 ETH per transaction
        
        saleActive = true;
    }
    
    /**
     * @dev Calculate how many tokens can be bought with given Ether amount
     * @param etherAmount Amount of Ether in wei
     * @return Number of tokens (with decimals)
     */
    function calculateTokenAmount(uint256 etherAmount) public view returns (uint256) {
        // tokens = (etherAmount * 10^18) / tokenPrice
        // This maintains precision with 18 decimal places
        return (etherAmount * 10**decimals) / tokenPrice;
    }
    
    /**
     * @dev Calculate how much Ether is needed for a specific token amount
     * @param tokenAmount Number of tokens desired (with decimals)
     * @return Amount of Ether needed in wei
     */
    function calculateEtherCost(uint256 tokenAmount) public view returns (uint256) {
        // ether = (tokenAmount * tokenPrice) / 10^18
        return (tokenAmount * tokenPrice) / 10**decimals;
    }
    
    /**
     * @dev Buy tokens by sending Ether to the contract
     * Automatically calculates token amount based on sent Ether
     */
    function buyTokens() public payable saleIsActive {
        require(msg.value >= minimumPurchase, "Purchase amount too low");
        require(msg.value <= maximumPurchase, "Purchase amount too high");
        
        // Calculate token amount
        uint256 tokenAmount = calculateTokenAmount(msg.value);
        
        require(tokenAmount > 0, "Must purchase at least 1 token");
        require(tokenAmount <= tokensAvailable, "Not enough tokens available");
        
        // Update state
        tokensAvailable -= tokenAmount;
        tokensSold += tokenAmount;
        totalEtherRaised += msg.value;
        
        // Transfer tokens to buyer
        balances[address(this)] -= tokenAmount;
        balances[msg.sender] += tokenAmount;
        
        // Track purchase
        purchases[msg.sender] += msg.value;
        
        emit TokensPurchased(msg.sender, msg.value, tokenAmount, block.timestamp);
    }
    
    /**
     * @dev Fallback function to receive Ether and automatically buy tokens
     */
    receive() external payable {
        buyTokens();
    }
    
    /**
     * @dev Get sale statistics
     * @return _tokenPrice Current price per token
     * @return _tokensAvailable Tokens still available for sale
     * @return _tokensSold Total tokens sold
     * @return _totalEtherRaised Total Ether raised from sales
     * @return _saleActive Whether the sale is currently active
     */
    function getSaleInfo() public view returns (
        uint256 _tokenPrice,
        uint256 _tokensAvailable,
        uint256 _tokensSold,
        uint256 _totalEtherRaised,
        bool _saleActive
    ) {
        return (
            tokenPrice,
            tokensAvailable,
            tokensSold,
            totalEtherRaised,
            saleActive
        );
    }
    
    /**
     * @dev Get purchase limits
     */
    function getPurchaseLimits() public view returns (uint256 min, uint256 max) {
        return (minimumPurchase, maximumPurchase);
    }
    
    /**
     * @dev Calculate the rate: how many tokens per 1 ETH
     * @return Number of tokens you get for 1 ETH
     */
    function getTokensPerEther() public view returns (uint256) {
        return calculateTokenAmount(1 ether);
    }
    
    // ========== OWNER FUNCTIONS ==========
    
    /**
     * @dev Update token price (owner only)
     * @param _newPrice New price per token in wei
     */
    function setTokenPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0, "Price must be greater than 0");
        uint256 oldPrice = tokenPrice;
        tokenPrice = _newPrice;
        emit PriceUpdated(oldPrice, _newPrice);
    }
    
    /**
     * @dev Set purchase limits (owner only)
     */
    function setPurchaseLimits(uint256 _minimum, uint256 _maximum) public onlyOwner {
        require(_minimum > 0, "Minimum must be greater than 0");
        require(_maximum > _minimum, "Maximum must be greater than minimum");
        minimumPurchase = _minimum;
        maximumPurchase = _maximum;
    }
    
    /**
     * @dev Toggle sale status (owner only)
     */
    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
        emit SaleStatusChanged(saleActive, block.timestamp);
    }
    
    /**
     * @dev End sale and stop accepting purchases (owner only)
     */
    function endSale() public onlyOwner {
        saleActive = false;
        emit SaleStatusChanged(false, block.timestamp);
    }
    
    /**
     * @dev Withdraw unsold tokens (owner only)
     * Can only be done after sale ends
     */
    function withdrawUnsoldTokens() public onlyOwner {
        require(!saleActive, "Cannot withdraw while sale is active");
        uint256 amount = balances[address(this)];
        require(amount > 0, "No tokens to withdraw");
        
        balances[address(this)] = 0;
        balances[owner] += amount;
        
        emit TokensWithdrawn(owner, amount);
    }
    
    /**
     * @dev Withdraw raised Ether (owner only)
     */
    function withdrawEther() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Ether transfer failed");
        
        emit EtherWithdrawn(owner, balance);
    }
    
    /**
     * @dev Partial Ether withdrawal (owner only)
     * @param amount Amount to withdraw in wei
     */
    function withdrawEtherPartial(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Ether transfer failed");
        
        emit EtherWithdrawn(owner, amount);
    }
    
    // ========== UTILITY FUNCTIONS ==========
    
    /**
     * @dev Check token balance
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    /**
     * @dev Get contract's Ether balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get purchase history for an address
     */
    function getPurchaseAmount(address buyer) public view returns (uint256) {
        return purchases[buyer];
    }
    
    /**
     * @dev Calculate sale progress percentage (0-100)
     */
    function getSaleProgress() public view returns (uint256) {
        if (tokensSold == 0) return 0;
        return (tokensSold * 100) / (tokensAvailable + tokensSold);
    }
}
