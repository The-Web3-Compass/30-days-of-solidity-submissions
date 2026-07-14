//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract SimplifiedTokenSale is SimpleERC20 {
    uint public tokenPrice;
    uint public saleStartTume;
    uint public saleEndTime；
    uint public minperchase;
    uint public maxPerchase;
    uint public totalRaised;
    address public projectOwner;
    bool public finalised = false;
    bool private initialTransferDone = false;
    event TokensPurchased(address indexed byer, uint etheramount, uint tokenamount);
    event SaleFinalised(uint totalRaised, uint totalTokenSold);
    constructor(uint _initialSupply, uint _tokenPrice, uint _saleDurationInSeconds, uint _minPurchase, uint _maxPurchase,address _projectOwner) SimpleERC20(_initialSupply) {
        tokenPrice = _tokenPrice;
        salesStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minpurchase = _minPurchase;
        maxPerchase = _maxPurchase;
        projectOwner = _projectOwner;
        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;
    }
    function isSaleActive() public view returns (bool) {
        return (!finalised && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime)；
    }
    function purchaseTokens() public payable {
        require(is SaleActive(), "Sale not active");
        require(msg.value >= minPurchase, "Amount below minimum");
        require(msg.value <= maxPerchase, "Amount exceeds maximum");
        uint tokenAmount = (mag.sender.value * 10**uint(decimals)) / tokenPrice;
        require (balanceOf[address(this)] >= tokenAmount, "Not enough tokens for sale");
        totalRaised += mag.value;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
        }
    function transfer(address _to, uint _value) public override returns (bool) {
        if (!finalised && msg.sender != address(this) && initialTransferDone) {
            require(false, "Tokens locked until sale finalised");
        }
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint _value) public override returns (bool) {
        if (!finalised && _from != address(this)) {
            require(false, "tokens locked until sale finalised");
        }
        return super.transferFrom(_from, _to, _value);
    }
    function finaliseSale() public payable {
        require(msg.sender == projectOwner, "Only project owner can finalise");
        require(!finalised, "Sale already finalised");
        require(block.timestamp > saleEndTime, "Sale period not yet ended");
        finalised = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];
        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "Transfer to project owner failed");
        emit SaleFinalized(totalRaised, tokensSold);
    }
          
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