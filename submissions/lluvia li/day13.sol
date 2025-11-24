// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Mytoken.sol";
contract simpletokensale is Mytoken {
    uint256 public tokenPrice;
    uint256 public saleStarTime;
    uint256 public salesEndTime;
    uint256 public miniPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;

    bool public finalized = false;
    bool private initialTransferDone = false;

    event TokenPurchased (address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event saleFinalized (uint256 totalRaised, uint256 totatokensSold);
    
    constructor(
    uint256 _initialSupply,
    uint256 _tokenPrice,
    uint256 _saleDurationInseconds,
    uint256  _miniPurchase,
    uint256  _maxPurchase,

    address  _projectOwner
    ) Mytoken(_initialSupply){

        tokenPrice=_tokenPrice;
        saleStarTime= block.timestamp;
        salesEndTime= block.timestamp+ _saleDurationInseconds;
        miniPurchase = _miniPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

//自己的钱转自己
        _transfer(msg.sender, address(this), totalSupply);

        initialTransferDone= true;

    }

    function isSaleActive () public view returns (bool){

        return (!finalized && block.timestamp >= saleStarTime && block.timestamp <= salesEndTime);

    }

    function buyTokens () public payable{
        require(isSaleActive(), "Sale is nor active");
        require(msg.value >= miniPurchase, "Amount is below minmiun purchese");
        require(msg.value <= maxPurchase ,"Amount exceeds max purchese");

        uint256 tokenAmount =(msg.value * 10** uint256 (decimals))/ tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount, "not enough tokens left for sale");
        
        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);

        emit TokenPurchased(msg.sender, msg.value, tokenAmount);

    }
    
    function transfer(address _to, uint256 _value) public override returns (bool){
        if (!finalized && msg.sender != address(this)&& initialTransferDone){
            require(false, "tokens are locked util sale is finalized");
        }

        return super.transfer(_to, _value);
    }

    function transferfrom (address _from, address _to, uint256 _value) public override returns (bool){
        if (!finalized && _from != address(this)){
            require(false, "tokens are locked util sale is finalized");
        }
        
        return super.transferfrom(_from, _to,  _value);
        
    }


    function finalizeSale() public payable {
    require(msg.sender == projectOwner, "Only Owner can call the function");
    require(!finalized, "Sale already finalized");
    require(block.timestamp > salesEndTime, "Sale not finished yet");

    finalized = true;
    uint256 tokensSold = totalSupply - balanceOf[address(this)];

    (bool success, ) = projectOwner.call{value: address(this).balance}("");
    require(success, "Transfer to project owner failed");

    emit saleFinalized(totalRaised, tokensSold);
    }

    function timeRemaining() public view returns (uint256) {
    if (block.timestamp >= salesEndTime) {
        return 0;
    }
    return salesEndTime - block.timestamp;
  }


    function tokenAvailable() public view returns (uint256){

        return balanceOf[address(this)];
    }

    receive() external payable {
        buyTokens();
    }
}




