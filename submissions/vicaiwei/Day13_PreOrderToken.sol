//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./MyToken.sol";

contract PreOrderToken is MyToken {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised; // Cumulative ETH collected
    address public projectOwner;
    bool public finalized = false;
    bool private initialTransferDone = false;

    event TokenPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event saleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    )MyToken(_initialSupply) {
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        // Transfers the entire supply from the deployer to the sale contract 
        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;
    }

    function isSaleActive() public view returns (bool) {
        return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    function buyTokens() public payable {
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below min purchase");
        require(msg.value <= maxPurchase, "Amount is above max purchase");

        uint256 tokenAmount = (msg.value * 10 ** uint256(decimals)) / tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");
        totalRaised += msg.value;
        // Sends tokens
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokenPurchased(msg.sender, msg.value, tokenAmount);
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            // If the sale is not finalized, the sender is not the contract itself, and initial tokens were moved
            require(false, "Tokens are locked until sale is finalized");
        }

        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if (!finalized &&  _from != address(this)) {
            // If the sale is not finalized and the source _from is not the contract, revert similarly
            require(false, "Tokens are locked until sale is finalized");
        }

        return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public payable {
        require(msg.sender == projectOwner, "Only owner can call this function");
        require(!finalized,"Sale is already finalized");
        require (block.timestamp > saleEndTime, "Sale not finished yet");
        finalized = true;
        uint256 tokenSold = totalSupply - balanceOf[address(this)];
        // Sends all ETH to projectOwner using a low‑level call,  avoids transfer()’s gas‑stipend pitfalls
        (bool success, ) = projectOwner.call{value : address(this).balance}("");
        require(success, "Transfer failed");
        emit saleFinalized(totalRaised, tokenSold);
    }

    function timeRemaining() public view  returns(uint256){
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return (saleEndTime - block.timestamp);
    }

    function tokensAvailable()public view returns(uint256){
        return balanceOf[address(this)];
    }

    receive() external payable{
        // Automatically routes direct ETH transfers to buyTokens()
        buyTokens();
    }
}