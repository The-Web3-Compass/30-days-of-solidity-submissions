// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./MyToken.sol";

contract PreOrderToken is MyToken {

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
    )MyToken(_initialSupply){
        tokenPrice = _tokenPrice;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;
    }

    function isSaleActive() public view returns(bool){
        return(!finalized && block.timestamp >= saleStartTime &&block.timestamp <=saleEndTime);
    }

    function buyTokens() public payable {
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below min Purchase");
        require(msg.value <= maxPurchase, "Amount is above max Purchase");
        uint256 tokenAmount = (msg.value * 10**uint256(decimals))/ tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount, "Not enough token left for sale");
        totalRaised += msg.value;
        _transfer(address(this),msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    function transferFrom(address _from, address _to,uint256 _value)public override returns(bool){
        if(!finalized && _from !=address(this)){
            require(false, "Token are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public payable {
        require(msg.sender == projectOwner, "Only owner can call this function");
        require(!finalized, "Sale is already finalized");
        require(block.timestamp > saleEndTime, "Sale not finished yet");
        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];
        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
        emit SaleFinalized(totalRaised, tokensSold);
    }

    function timeRemaining() public view returns(uint256){
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return (saleEndTime - block.timestamp);
    }

    function tokensAvailable() public view returns(uint256){
        return balanceOf[address(this)];
    }

    receive() external payable {
        buyTokens();
     }

}