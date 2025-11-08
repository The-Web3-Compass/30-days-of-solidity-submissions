//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./MyToken.sol";

contract PreOrderToken is MyToken {

    uint256 public TokenPrice;
    uint256 public SaleStartTime;
    uint256 public SaleEndTime;
    uint256 public MinPurchase;
    uint256 public MaxPurchase;
    uint256 public TotalRaised;
    address public ProjectOwner;
    bool public Finalized = false;
    bool public InitialTransferDone = false;

    event TokensPurchased(address indexed buyer, uint256 EtherAmount, uint256 TokenAmount);
    event SaleFinalized(uint256 TotalRaised, uint256 TotalTokensSold);

    constructor(
        uint256 _InitialSupply,
        uint256 _TokenPrice,
        uint256 _SaleDurationInSeconds,
        uint256 _MinPurchase,
        uint256 _MaxPurchase,
        address _ProjectOwner
    )
    MyToken(_InitialSupply){
        TokenPrice = _TokenPrice;
        SaleStartTime = block.timestamp;
        SaleEndTime = block.timestamp + _SaleDurationInSeconds;
        MinPurchase = _MinPurchase;
        MaxPurchase = _MaxPurchase;
        ProjectOwner = _ProjectOwner;

        _transfer(msg.sender, address(this), TotalSupply);
        InitialTransferDone = true;

    }

    function isSaleActive() public view returns(bool){
        return(!Finalized && block.timestamp >= SaleStartTime &&block.timestamp <= SaleEndTime);

    }

    function BuyTokens() public payable{
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= MinPurchase, "Amount is below min purchase");
        require(msg.value <= MaxPurchase, "Amount is above max purchase");
        uint256 TokenAmount = (msg.value * 10 ** (Decimals))/ TokenPrice;
        require(BalanceOf[address(this)] >= TokenAmount, "Not enough tokens left for sale");
        TotalRaised += msg.value;
        _transfer(address(this), msg.sender, TokenAmount);
        emit TokensPurchased(msg.sender, msg.value, TokenAmount);

    }

    function transfer(address _to,uint256 _value) public override returns(bool){
        if(!Finalized && msg.sender != address(this) && InitialTransferDone){
            require(false, "Tokens are locked until sale is finalized");

        }
        return super.transfer(_to, _value);

    }

    function transferfrom(address _from, address _to, uint256 _value) public override returns(bool){
        if(!Finalized && _from != address(this)){
            require(false, "Tokens are locked until sale is finalized");

        }
        return super.transferfrom(_from, _to, _value);

    }

    function FinalizeSale() public payable{
        require(msg.sender ==ProjectOwner, "Only owner can call this function");
        require(!Finalized, "Sale is already finalized");
        require(block.timestamp > SaleEndTime, "Sale not finished yet");
        Finalized = true;
        uint256 TokensSold = TotalSupply - BalanceOf[address(this)];
        (bool success,) = ProjectOwner.call{value:address(this).balance}("");
        require(success, "Transfer failed");
        emit SaleFinalized(TotalRaised, TokensSold);

    }

    function TimeRemaining() public view returns(uint256){
        if(block.timestamp >= SaleEndTime){
            return 0;

        }
        return (SaleEndTime - block.timestamp);

    }

    function TokenAvailable() public view returns(uint256){
        return BalanceOf[address(this)];

    }

    receive() external payable{
        BuyTokens();
    }

}
