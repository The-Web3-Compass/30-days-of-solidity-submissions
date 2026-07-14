//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day12-SimpleERC20.sol";

contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public startTime;
    uint256 public endTime;
    uint256 public maximumPurchase;
    uint256 public minimumPurchase;
    uint256 public tokenPrice;
    uint256 public totalRaised;
    address public tokenOwner;
    bool public isEnded;
    bool private isInitialTransfered;

    event TokenPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event TokenSaleEnded(uint256 totalRaised, uint256 totalTokensSold);

    constructor(
        uint256 _initialSupply,
        uint256 _durationInSeconds,
        uint256 _maxPurchase,
        uint256 _minPurchase,
        uint256 _tokenPrice,
        address _owner
    ) SimpleERC20(_initialSupply) {
        startTime = block.timestamp;
        endTime = block.timestamp + _durationInSeconds;
        maximumPurchase = _maxPurchase;
        minimumPurchase = _minPurchase;
        tokenPrice = _tokenPrice;
        tokenOwner = _owner;

        // transfer all tokens form deployer to this contract for sale
        _transfer(msg.sender, address(this), totalSupply);
        isInitialTransfered = true;
    }

    // check if the sale is currently live
    function isActive() public view returns(bool) {
        return (!isEnded && isInitialTransfered && block.timestamp >= startTime && block.timestamp <= endTime);
    }

    function buyTokens() public payable {
        require(isActive(), "Sale is not active");
        require(msg.value >= minimumPurchase, "Amount is below minimum purchase");
        require(msg.value <= maximumPurchase, "Amount exceeds maximum purchase");

        // calculate amount of tokens to be bought
        uint256 tokensPurchased = msg.value * (10**18) / tokenPrice;
        require(tokensPurchased <= balanceOf[address(this)], "Insufficient tokens");

        totalRaised += msg.value;

        // transfer tokens from contract to buyer
        _transfer(address(this), msg.sender, tokensPurchased);
        emit TokenPurchased(msg.sender, tokensPurchased, msg.value);
    }

    function transfer(address _to, uint256 _amount) public override returns(bool) {
        if(!isEnded && isInitialTransfered && msg.sender != address(this)) {
            require(false, "transfer is blocked during token sale");
        }
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns(bool) {
        if(!isEnded && isInitialTransfered && _from != address(this)) {
            require(false, "transfer is blocked during token sale");
        }
        return super.transferFrom(_from, _to, _amount);
    }

    function finalizeSale() public payable {
        require(msg.sender == tokenOwner, "Only owner can finalize sale");
        require(!isEnded, "Sale is already ended");
        require(block.timestamp > endTime, "Sale not finished");

        isEnded = true;
        (bool success, ) = tokenOwner.call{value : address(this).balance}("");
        require(success, "Transfer to owner failed");
        _transfer(address(this), tokenOwner, balanceOf[address(this)]);

        uint256 totalSale = totalSupply - balanceOf[address(this)];
        emit TokenSaleEnded(totalRaised, totalSale);
    }

    function timeRemaining() public view returns(uint256) {
        if (block.timestamp >= endTime) return 0;
        else return endTime - block.timestamp;
    }

    function tokensAvailable() public view returns(uint256) {
        return balanceOf[address(this)];
    }

    function reveive() external payable {
        buyTokens();
    }
}