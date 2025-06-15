// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
import "./Day12-SimpleERC20.sol";

contract SimplifiedTokenSale is SimpleERC20{

    address public owner;
    uint256 public tokenPrice;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    // Has the sale been officially closed?
    bool public finalized = false;
    // Used to ensure the contract received all tokens before locking transfers
    bool private initialTransferDone = false;

    event TokensPurchased(address indexed buyer,uint256 ethereAmount,uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    constructor(
        address _owner,
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase
    ) SimpleERC20(_initialSupply) {
        owner = _owner;
        tokenPrice = _tokenPrice;
        startTimestamp = block.timestamp;
        endTimestamp = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    
        // Transfer all tokens to this contract for sale
        _transfer(msg.sender, address(this), totalSupply);

        // Mark that we've moved tokens from the deployer
        initialTransferDone = true;
    }

    function isSaleActive() public view returns(bool){
        bool isActive = true;
        if (block.timestamp < startTimestamp) isActive = false;
        if (block.timestamp >= endTimestamp) isActive = false;
        

        return isActive;
    }

    function buyTokens() public payable{
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below minimum purchase");
        require(msg.value <= maxPurchase, "Amount exceeds maximum purchase");
        uint256 tokenAmount = msg.value * 10 ** 18 / tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");
        

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, msg.value);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);

    }

    /** Locking Direct Transfers */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        
        require((!finalized && msg.sender != address(0) && initialTransferDone), 
        "Tokens are locked until sale is finalized");
        //  This performs the actual transfer logic.
        return super.transfer(_to, _value);
    }

    /**  Locking Delegated Transfers */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
       
        require((!finalized && _from != address(this)), "Tokens are locked until sale is finalized");
        return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public payable {
        require(msg.sender == owner, "Only Owner can call the function");
        require(!finalized, "Sale already finalized");
        require(block.timestamp > endTimestamp, "Sale not finished yet");

        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];

        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer to project owner failed");

        emit SaleFinalized(totalRaised, tokensSold);
    }

      
    receive() external payable {
        buyTokens();
    }



      
    function timeRemaining() public view returns (uint256) {
        if (block.timestamp >= endTimestamp){
            return 0;
        }else{
            return endTimestamp - block.timestamp;
        }   
            
    }

    function tokensAvailable() public view returns (uint256) {
        return balanceOf[address(this)];
    }








}