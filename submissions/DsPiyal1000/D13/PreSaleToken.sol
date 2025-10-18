// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; 

import "./SimpleToken.sol";

contract PreSaleToken is SimpleERC20 {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;
    bool public finalized = false;
    bool private initialTransferDone = false;
    bool private locked = false;

    modifier noReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyProjectOwner() {
        require(msg.sender == projectOwner, "Only project owner");
        _;
    }

    event TokenPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount, uint256 totalRaised);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) SimpleERC20(_initialSupply) {
        require(_tokenPrice > 0, "Token price must be greater than 0");
        require(_saleDurationInSeconds > 0, "Sale duration must be greater than 0");
        require(_minPurchase > 0, "Min purchase must be greater than 0");
        require(_maxPurchase >= _minPurchase, "Max purchase must be >= min purchase");
        require(_projectOwner != address(0), "Invalid project owner address");

        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;
    }

    function isSaleActive() public view returns (bool) {
        uint256 currentTime = block.timestamp;
        return (!finalized && currentTime >= saleStartTime && currentTime <= saleEndTime);
    }

    function buyToken() public payable noReentrant {
        require(isSaleActive(), "Sale not active");
        require(msg.value >= minPurchase, "Purchase amount too low");
        require(msg.value <= maxPurchase, "Purchase amount too high");
        require(msg.value > 0, "Cannot purchase with 0 ETH");

        uint256 tokenAmount;
        unchecked {
            tokenAmount = (msg.value * 1e18) / tokenPrice;
        }
        require(tokenAmount > 0, "Token amount must be greater than 0");
        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens available");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);

        emit TokenPurchased(msg.sender, msg.value, tokenAmount, totalRaised);
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0), "Destination cannot be null");
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            revert("Cannot transfer tokens during sale period");
        }
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0), "Destination cannot be null");
        if (!finalized && _from != address(this) && initialTransferDone) {
            revert("Cannot transfer tokens during sale period");
        }
        return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public onlyProjectOwner noReentrant {
        require(!finalized, "Sale already finalized");
        require(block.timestamp >= saleEndTime, "Sale still active");
        require(block.timestamp >= saleStartTime, "Sale not started");

        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];
        uint256 ethToTransfer = address(this).balance;

        (bool success, ) = projectOwner.call{value: ethToTransfer}("");
        require(success, "Failed to transfer ETH to project owner");

        emit SaleFinalized(totalRaised, tokensSold);
    }

    function timeRemaining() public view returns (uint256) {
        return block.timestamp >= saleEndTime ? 0 : saleEndTime - block.timestamp;
    }

    function tokensAvailable() public view returns (uint256) {
        return balanceOf[address(this)];
    }

    function getTokenAmount(uint256 ethAmount) public view returns (uint256) {
        require(ethAmount > 0, "ETH amount must be greater than 0");
        return (ethAmount * 1e18) / tokenPrice;
    }

    receive() external payable {
        require(msg.value > 0, "Cannot send 0 ETH");
        buyToken();
    }
}