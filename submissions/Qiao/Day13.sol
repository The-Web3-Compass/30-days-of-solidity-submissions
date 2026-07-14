// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../Day12.sol";

contract SimplifiedTokensale is SimpleERC20 {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    uint256 public totalTokensSold;
    address public owner;
    bool public saleFinalized = false;
    bool private initialTransferDone = false;

    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDuration,
        uint256 _minPurchase,
        uint256 _maxPurchase
        //, address _owner
        ) SimpleERC20(_initialSupply) {
            tokenPrice = _tokenPrice;
            saleStartTime = block.timestamp;
            saleEndTime = block.timestamp + _saleDuration;
            minPurchase = _minPurchase;
            maxPurchase = _maxPurchase;
            //owner = _owner;
            owner = msg.sender;

        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;
   }

    function isSaleActive() public view returns (bool) {
        return !saleFinalized && block.timestamp <= saleEndTime;
    }

    function buyTokens() public payable {
        require(msg.value >= minPurchase, "Purchase amount too low");
        require(msg.value <= maxPurchase, "Purchase amount too high.");
        require(isSaleActive(), "Sale is not active.");

        uint256 tokenAmount = (msg.value * 10**uint256(decimals)) / tokenPrice;
        require(tokenAmount <= balances[address(this)], "Insufficient tokens.");
        totalRaised += msg.value;
        totalTokensSold += tokenAmount;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // fallback
    receive() external payable {
        buyTokens();
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (!saleFinalized && msg.sender != address(this) && initialTransferDone) {
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if (!saleFinalized && _from != address(this)) {
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public payable onlyOwner{
        // set saleFinalized to true to officially end the sale
        require(!saleFinalized, "Sale has already been finalized.");
        require(msg.sender == owner, "Only owner can finalize sale.");
        require(block.timestamp >= saleEndTime, "Sale has not ended yet.");
        saleFinalized = true;

        // transfer the contract balance to the owner
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer to project owner failed");

        emit SaleFinalized(totalRaised, totalTokensSold);
    }

    function timeRemaining() public view returns (uint256) {
        if (block.timestamp >= saleEndTime) {
            return 0;
        }
    return saleEndTime - block.timestamp;
   }

    function tokensAvailable() public view returns (uint256) {
        return balances[address(this)];
    }
}