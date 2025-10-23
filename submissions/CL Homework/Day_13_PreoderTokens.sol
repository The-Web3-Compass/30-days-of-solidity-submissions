// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PreorderTokens is ERC20 {
    // ───────────────────────────────
    // 📦 State Variables
    // ───────────────────────────────
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;

    bool public initialTransferDone;
    bool public finalized;

    // ───────────────────────────────
    // 📢 Events
    // ───────────────────────────────
    event TokensPurchased(address indexed buyer, uint256 amountPaid, uint256 tokensBought);
    event SaleFinalized(uint256 totalRaised, uint256 tokensSold);

    // ───────────────────────────────
    // 🏗️ Constructor
    // ───────────────────────────────
    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) ERC20("PreorderTokens", "STKN") {
        // Mint all tokens to the deployer
        _mint(msg.sender, _initialSupply * 10 ** decimals());
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        // Transfer all tokens to the contract for sale
        _transfer(msg.sender, address(this), totalSupply());

        initialTransferDone = true;
    }

    // ───────────────────────────────
    // 💰 Token Purchase Logic
    // ───────────────────────────────
    function buyTokens() public payable {
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Below minimum purchase");
        require(msg.value <= maxPurchase, "Above maximum purchase");

        uint256 tokenAmount = (msg.value * 10 ** decimals()) / tokenPrice;
        require(balanceOf(address(this)) >= tokenAmount, "Not enough tokens left");

        totalRaised += msg.value;

        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // ───────────────────────────────
    // 🔒 Lock Tokens Until Finalization
    // ───────────────────────────────
    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            revert("Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if (!finalized && _from != address(this)) {
            revert("Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    // ───────────────────────────────
    // 🧾 Sale Finalization
    // ───────────────────────────────
    function finalizeSale() public {
        require(msg.sender == projectOwner, "Only owner can finalize");
        require(!finalized, "Already finalized");
        require(block.timestamp > saleEndTime, "Sale not finished yet");

        finalized = true;

        uint256 tokensSold = totalSupply() - balanceOf(address(this));

        // Send all raised ETH to the project owner
        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");

        emit SaleFinalized(totalRaised, tokensSold);
    }

    // ───────────────────────────────
    // ⏱️ Helper View Functions
    // ───────────────────────────────
    function isSaleActive() public view returns (bool) {
        return block.timestamp >= saleStartTime && block.timestamp <= saleEndTime && !finalized;
    }

    function timeRemaining() public view returns (uint256) {
        if (block.timestamp >= saleEndTime) {
            return 0;
        }
        return saleEndTime - block.timestamp;
    }

    function tokensAvailable() public view returns (uint256) {
        return balanceOf(address(this));
    }

    // ───────────────────────────────
    // ⚡ Allow ETH Direct Purchases
    // ───────────────────────────────
    receive() external payable {
        buyTokens();
    }
}
