// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TokenSale
 * @dev A self-contained ERC20 token and token sale contract.
 * The token is minted at deployment, held by the contract,
 * and sold for Ether at a fixed price within a time window.
 */

contract TokenSale {
    // ======== Token Logic ========

    string public name = "PreSaleToken";
    string public symbol = "PST";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // ======== Sale Logic ========

    address public owner;
    uint256 public tokenPrice;          // in wei per token
    uint256 public saleStart;           // timestamp
    uint256 public saleEnd;             // timestamp
    uint256 public minPurchase;         // in wei
    uint256 public maxPurchase;         // in wei
    uint256 public totalRaised;         // total ETH raised
    bool public finalized;              // sale finalized?
    bool public paused;                 // sale paused?

    event TokensPurchased(address indexed buyer, uint256 etherSpent, uint256 tokensBought);
    event SaleFinalized(uint256 totalRaised, uint256 tokensSold);
    event Paused();
    event Resumed();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier saleActive() {
        require(block.timestamp >= saleStart && block.timestamp <= saleEnd, "Sale inactive");
        require(!paused, "Sale paused");
        require(!finalized, "Sale finalized");
        _;
    }

    constructor(
        uint256 _totalSupply,
        uint256 _tokenPrice,
        uint256 _durationSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase
    ) {
        owner = msg.sender;
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balances[address(this)] = totalSupply;

        tokenPrice = _tokenPrice;
        saleStart = block.timestamp;
        saleEnd = block.timestamp + _durationSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;

        emit Transfer(address(0), address(this), totalSupply);
    }

    // ======== ERC20 Core ========

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address holder, address spender) public view returns (uint256) {
        return allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(finalized, "Transfers locked until sale ends");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(finalized, "Transfers locked until sale ends");
        uint256 allowed = allowances[from][msg.sender];
        require(allowed >= amount, "Allowance too low");
        allowances[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Invalid address");
        uint256 bal = balances[from];
        require(bal >= amount, "Insufficient balance");
        balances[from] = bal - amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    // ======== SALE FUNCTIONS ========

    function buyTokens() public payable saleActive {
        require(msg.value >= minPurchase, "Below min purchase");
        require(msg.value <= maxPurchase, "Above max purchase");

        uint256 tokenAmount = (msg.value * 10 ** uint256(decimals)) / tokenPrice;
        require(balances[address(this)] >= tokenAmount, "Not enough tokens left");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    function pauseSale() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function resumeSale() external onlyOwner {
        paused = false;
        emit Resumed();
    }

    function finalizeSale() external onlyOwner {
        require(block.timestamp > saleEnd, "Sale not ended yet");
        require(!finalized, "Already finalized");

        finalized = true;
        uint256 unsold = balances[address(this)];

        // Burn unsold tokens (optional)
        if (unsold > 0) {
            balances[address(this)] = 0;
            totalSupply -= unsold;
            emit Transfer(address(this), address(0), unsold);
        }

        // Send raised ETH to owner
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "ETH transfer failed");

        emit SaleFinalized(totalRaised, totalSupply - unsold);
    }

    //  v IEW HELPERS 

    function tokensAvailable() public view returns (uint256) {
        return balances[address(this)];
    }

    function timeRemaining() public view returns (uint256) {
        return block.timestamp >= saleEnd ? 0 : saleEnd - block.timestamp;
    }

    // RECEIVE FALLBACK 

    receive() external payable {
        buyTokens();
    }
}