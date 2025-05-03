// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./day12-contract.sol";

contract PreOrderToken is MyFirstToken {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;
    bool public finalized = false;
    bool public initialTransferDone = false;

    event TokenPurchased(
        address indexed buyer,
        uint etherAmount,
        uint tokenAmount
    );
    event SaleFinalized(uint totalRaised, uint totalTokenSold);

    constructor(
        uint _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) MyFirstToken(_initialSupply) {
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
        return (!finalized &&
            block.timestamp >= saleStartTime &&
            block.timestamp <= saleEndTime);
    }

    function buyTokens() public payable {
        require(isSaleActive(), "sale is closed");
        require(msg.value >= minPurchase, "amount is below min purchase value");
        require(msg.value <= maxPurchase, "amount is above max purchase value");

        uint tokenAmount = (msg.value * (10 ** uint(decimals))) / tokenPrice;

        require(balanceOf[address(this)] >= tokenAmount, "not ewough tokens");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);

        emit TokenPurchased(msg.sender, msg.value, tokenAmount);
    }

    function transfer(address _to, uint _value) public override returns (bool) {
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            require(false, "token are locked until sale is finalized");
        }

        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) public override returns (bool) {
        if (!finalized && msg.sender != address(this)) {
            require(false, "tokens are locked until sale is live");
        }

        return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public payable {
        require(msg.sender == projectOwner, "unauthorized");
        require(!finalized, "sale is already finalized");
        require(block.timestamp > saleEndTime, "sale is still live");

        finalized = true;
        uint tokenSold = totalSupply - balanceOf[address(this)];
        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "transaction failed");

        emit SaleFinalized(totalRaised, tokenSold);
    }

    function timeRemaining() public view returns (uint) {
        if (block.timestamp >= saleEndTime) {
            return 0;
        }

        return saleEndTime - block.timestamp;
    }

    function tokenAvailable() public view returns (uint) {
        return balanceOf[address(this)];
    }

    receive() external payable {
        buyTokens();
    }
}
