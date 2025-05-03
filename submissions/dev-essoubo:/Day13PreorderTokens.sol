// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IERC20 
 * @dev Interface for the ERC20 standard
 */
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/**
 * @title PreorderTokens
 * @dev Contract for selling tokens in exchange for Ether
 */
contract PreorderTokens {
    // State variables
    IERC20 public token;              // The ERC20 token being sold
    address public owner;             // Contract owner/admin
    uint256 public tokenPrice;        // Price in wei per token (1 ether = 10^18 wei)
    uint256 public tokensSold;        // Counter for total tokens sold
    uint256 public saleStartTime;     // When the sale starts
    uint256 public saleEndTime;       // When the sale ends
    uint256 public minPurchase;       // Minimum purchase amount in tokens
    uint256 public maxPurchase;       // Maximum purchase amount in tokens
    uint256 public hardCap;           // Maximum tokens to sell in this sale
    bool public saleActive;           // Whether the sale is currently active
    
    // Mapping to track purchases by address
    mapping(address => uint256) public tokensPurchased;
    
    // Events
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event SaleStatusChanged(bool newStatus);
    event PriceChanged(uint256 newPrice);
    event EtherWithdrawn(uint256 amount);
    
    /**
     * @dev Constructor to set up the presale
     * @param _token Address of the ERC20 token being sold
     * @param _tokenPrice Price of each token in wei
     * @param _saleStartTime When the sale starts (unix timestamp)
     * @param _saleDuration Duration of the sale in seconds
     * @param _minPurchase Minimum purchase amount in tokens
     * @param _maxPurchase Maximum purchase amount in tokens
     * @param _hardCap Maximum number of tokens to sell
     */
    constructor(
        address _token,
        uint256 _tokenPrice,
        uint256 _saleStartTime,
        uint256 _saleDuration,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        uint256 _hardCap
    ) {
        require(_token != address(0), "Token cannot be the zero address");
        require(_tokenPrice > 0, "Token price must be greater than zero");
        require(_maxPurchase >= _minPurchase, "Max purchase must be >= min purchase");
        require(_hardCap > 0, "Hard cap must be greater than zero");
        
        token = IERC20(_token);
        tokenPrice = _tokenPrice;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleStartTime + _saleDuration;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        hardCap = _hardCap;
        owner = msg.sender;
        saleActive = false;
    }
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    
    modifier saleIsActive() {
        require(saleActive, "Sale is not active");
        require(block.timestamp >= saleStartTime, "Sale has not started yet");
        require(block.timestamp <= saleEndTime, "Sale has ended");
        require(tokensSold < hardCap, "Hard cap reached");
        _;
    }
    
    /**
     * @dev Function to buy tokens with Ether
     */
    function buyTokens() public payable saleIsActive {
        uint256 tokenAmount = calculateTokenAmount(msg.value);
        
        require(tokenAmount >= minPurchase, "Below minimum purchase amount");
        require(tokenAmount <= maxPurchase, "Exceeds maximum purchase amount");
        require(tokensSold + tokenAmount <= hardCap, "Purchase would exceed hard cap");
        
        // Check if the contract has enough tokens
        require(token.balanceOf(address(this)) >= tokenAmount, "Contract has insufficient tokens");
        
        // Update state
        tokensSold += tokenAmount;
        tokensPurchased[msg.sender] += tokenAmount;
        
        // Transfer tokens to buyer
        bool success = token.transfer(msg.sender, tokenAmount);
        require(success, "Token transfer failed");
        
        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
    }
    
    /**
     * @dev Calculate how many tokens the buyer will receive for the provided ETH
     * @param weiAmount Amount of wei sent
     * @return Number of tokens the buyer will receive
     */
    function calculateTokenAmount(uint256 weiAmount) public view returns (uint256) {
        return (weiAmount * (10**18)) / tokenPrice;
    }
    
    /**
     * @dev Calculate how much ETH is needed to buy a specific amount of tokens
     * @param tokenAmount Number of tokens to buy
     * @return Amount of wei needed
     */
    function calculateCost(uint256 tokenAmount) public view returns (uint256) {
        return (tokenAmount * tokenPrice) / (10**18);
    }
    
    /**
     * @dev Start or pause the token sale
     * @param _saleActive New status of the sale
     */
    function setSaleStatus(bool _saleActive) public onlyOwner {
        saleActive = _saleActive;
        emit SaleStatusChanged(_saleActive);
    }
    
    /**
     * @dev Update the token price
     * @param _tokenPrice New price in wei per token
     */
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        require(_tokenPrice > 0, "Token price must be greater than zero");
        tokenPrice = _tokenPrice;
        emit PriceChanged(_tokenPrice);
    }
    
    /**
     * @dev Update sale timeframe
     * @param _saleStartTime New start time
     * @param _saleDuration New duration in seconds
     */
    function updateSaleTiming(uint256 _saleStartTime, uint256 _saleDuration) public onlyOwner {
        saleStartTime = _saleStartTime;
        saleEndTime = _saleStartTime + _saleDuration;
    }
    
    /**
     * @dev Update purchase limits
     * @param _minPurchase New minimum purchase in tokens
     * @param _maxPurchase New maximum purchase in tokens
     */
    function updatePurchaseLimits(uint256 _minPurchase, uint256 _maxPurchase) public onlyOwner {
        require(_maxPurchase >= _minPurchase, "Max purchase must be >= min purchase");
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }
    
    /**
     * @dev Withdraw ETH from the contract
     */
    function withdrawEther() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed");
        
        emit EtherWithdrawn(balance);
    }
    
    /**
     * @dev Allow owner to withdraw unsold tokens
     */
    function recoverTokens() public onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "No tokens to recover");
        
        bool success = token.transfer(owner, tokenBalance);
        require(success, "Token recovery failed");
    }
    
    /**
     * @dev Check the remaining tokens available for sale
     * @return Number of tokens still available
     */
    function availableTokens() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    /**
     * @dev Check if sale is currently active
     * @return Whether purchases can be made now
     */
    function isSaleOpen() public view returns (bool) {
        return (
            saleActive &&
            block.timestamp >= saleStartTime &&
            block.timestamp <= saleEndTime &&
            tokensSold < hardCap &&
            availableTokens() > 0
        );
    }
    
    /**
     * @dev Get time remaining in the sale
     * @return Seconds remaining in the sale (0 if ended)
     */
    function timeRemaining() public view returns (uint256) {
        if (block.timestamp >= saleEndTime) {
            return 0;
        }
        return saleEndTime - block.timestamp;
    }
}