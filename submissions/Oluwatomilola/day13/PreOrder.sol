// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleTokenSale is HadassahToken {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    bool public finalized;
    address public projectOwner = false;
    bool private initialTransferDone = false;

    event TokensPurchased (address indexed buyer, uint256 etherAmount, uint256 tokenAmount); 
    event saleFinalised(uint256 totalRaised, uint256 totalTokenSold);

    constructor(
       uint256 _initialSupply;
       uint256 _tokenPrice;
       uint256 _saleDurationInSecs;
       uint256 _minPurchase;
       uint256 _maxPurchase;
       address _projectOwner;
       ) HadassahToken(_initialSupply) {
        tokenPrice = _tokenPrice;
        saleEndTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        _transfer(msg.sender, address(this), totalSupply)    
       initialTransferDone = True;
       }

    function isSetActive() public view returns (bool) {
        return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }   

    function buyTokens() public payable {
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below minimum purchase");
        require(msg.value <= maxPurchase, "Amount exceeds maximum purchase");

        uint256 tokenAmount = (msg.value * 10**uint256(decimals)) / tokenPrice;
        require(balancOf[address(this)] >= tokenAmount, "Not Enough tokens left for sale");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            require(false, "Tokens are locked until safe is finalized");
        }
        return super.transfer(_to,_value);

    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if (!finalized && _from != address(this)) {
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public payable {
        require(msg.sender == projectOwner, "Only owner call the function)");
        require(!finalized, "sale already finalized");
        require(block.time > saleEndTime, "sale not finished yet");

        finalized = true;
        uint256 tokenSold = totalSupply - balanceOf[address(this)];

        (bool success, ) = projectOwner.call{Value: address(this).balance}("");
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
