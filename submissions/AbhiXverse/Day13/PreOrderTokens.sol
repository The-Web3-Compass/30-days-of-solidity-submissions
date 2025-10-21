// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./MyFirstToken.sol";

// This contract is a pre-order token sale contract that allows users to purchase tokens before the official launch of the token.
contract PreOrderTokens is MyFirstToken {

    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;
    bool public finalised = false;
    bool private initialTransferDone = false;

    // Events to log token purchases and sale finalisation
    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalised(uint256 totalRaised, uint256 tokensSold);


    // Constructor to initialize the token sale parameters
    constructor(
    uint256 _initialSupply, 
    uint256 _tokenPrice,
    uint256 _saleDuration,       
    uint256 _minPurchase,
    uint256 _maxPurchase,
    address _projectOwner
    ) MyFirstToken (_initialSupply) {
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = saleStartTime + _saleDuration;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;
       
        _transfer(address(this), msg.sender, _initialSupply);
        initialTransferDone = true;
    }

    // Function to check if the sale is active
    function isSaleActive() public view returns(bool) {
        return (!finalised && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    // Function to buy tokens during the sale
    function buyToken() public payable {
        require(isSaleActive(), "Sale is not active now");
        require(msg.value >= minPurchase, "Out of Range");
        require(msg.value <= maxPurchase, "Out of Range");

        uint256 tokenAmount = (msg.value * 10 ** uint256(decimals))/ tokenPrice;

        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens available");
        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }
  
    // Function to transfer tokens, with restrictions based on the sale status
    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (!finalised && msg.sender != address(this) && initialTransferDone) {
            require(false, "token are locked until is finalised");
        }
        return super.transfer(_to, _value);
    }
  
    // Function to transfer tokens from one address to another, with restrictions based on the sale status
    function transferFrom (address _from, address _to, uint256 _value) public override returns (bool) {
        if (!finalised && _from != address(this)) {
            require(false, "token are locked until is finalised");
        }
        return super.transferFrom(_from, _to, _value);
    }

    // Function to finalise the sale, transferring the raised funds to the project owner
    function finaliseSale() public payable {
        require (msg.sender == projectOwner, "Only owner can call");
        require(!finalised, "Already finalised");
        require(block.timestamp > saleEndTime, "Sale is not ended");
        finalised = true;

        uint256 tokensSold = totalSupply  - balanceOf[address(this)];
        (bool success, ) = projectOwner.call{value: address(this).balance}(""); 
        require(success, "transfer falied");
        emit SaleFinalised(totalRaised, tokensSold);
   }

    // Function to withdraw funds from the contract, only callable by the project owner
    function timeRemaining() public view returns (uint256) {
    if (block.timestamp >= saleEndTime) {
        return 0;
    }  
     return (saleEndTime - block.timestamp);
    }

    function tokensAvailable() public view returns (uint256) {
        return balanceOf[address(this)];
    }


    // receive function to allow users to buy tokens by sending Ether directly to the contract
    receive() external payable {
        buyToken();
    }
}