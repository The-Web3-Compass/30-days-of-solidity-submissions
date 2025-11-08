// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
contract SimplifiedTokensale is SimpleERC20 {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;
    bool public finalized = false;
    bool private initialTransferDone = false;


    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    
     constructor(
     uint256 _initialSupply,
     uint256 _tokenPrice,
     uint256 _saleDurationInSeconds,
     uint256 _minPurchase,
     uint256 _maxPurchase,
    address _projectOwner
    ) SimpleERC20(_initialSupply) {
    tokenPrice = _tokenPrice;
    saleStartTime = block.timestamp;
    saleEndTime = block.timestamp + _saleDurationInSeconds;
    minPurchase = _minPurchase;
    maxPurchase = _maxPurchase;
    projectOwner = _projectOwner;

    // Transfer all tokens to this contract for sale
    _transfer(msg.sender, address(this), totalSupply);

    // Mark that we've moved tokens from the deployer
    initialTransferDone = true;
   }
   function isSaleActive() public view returns (bool) {
    return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
  }
    
   function buyTokens() public payable {
    require(isSaleActive(), "Sale is not active");
    require(msg.value >= minPurchase, "Amount is below minimum purchase");
    require(msg.value <= maxPurchase, "Amount exceeds maximum purchase");

    uint256 tokenAmount = (msg.value * 10**uint256(decimals)) / tokenPrice;
    require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");

    totalRaised += msg.value;
    _transfer(address(this), msg.sender, tokenAmount);
    emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

      
   function transfer(address _to, uint256 _value) public override returns (bool) {
    if (!finalized && msg.sender != address(this) && initialTransferDone) {
        require(false, "Tokens are locked until sale is finalized");
    }
    return super.transfer(_to, _value);
   }

     
  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    if (!finalized && _from != address(this)) {
        require(false, "Tokens are locked until sale is finalized");
    }
    return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public payable {
    require(msg.sender == projectOwner, "Only Owner can call the function");
    require(!finalized, "Sale already finalized");
    require(block.timestamp > saleEndTime, "Sale not finished yet");

    finalized = true;
    uint256 tokensSold = totalSupply - balanceOf[address(this)];

    (bool success, ) = projectOwner.call{value: address(this).balance}("");
    require(success, "Transfer to project owner failed");

    emit SaleFinalized(totalRaised, tokensSold);
    }

      
   require(msg.sender == projectOwner, "Only Owner can call the function");
   require(!finalized, "Sale already finalized");
   require(block.timestamp > saleEndTime, "Sale not finished yet");

     
   function timeRemaining() public view returns (uint256) {
    if (block.timestamp >= saleEndTime) {
        return 0;
    }
    return saleEndTime - block.timestamp;
   }
     
   function tokensAvailable() public view returns (uint256) {
    return balanceOf[address(this)];
   
   }

     
  receive() external payable {
    buyTokens();
  }





















}