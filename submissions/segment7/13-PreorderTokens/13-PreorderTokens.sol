//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./12-SimpleToken/SimpleToken.sol";

contract PreOrderToken is SimpleERC20 {

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
/*Quick reminder:

    function transfer(address _to, uint256 _value) public virtual returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

*/
    constructor( 
        uint256 _intitialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    )SimpleERC20(_intitialSupply){
        /*
        constructor(uint256 _initialSupply) {
            totalSupply = _initialSupply * (10 ** uint256(decimals));
            balanceOf[msg.sender] = totalSupply;
            emit Transfer(address(0), msg.sender, totalSupply);
        }
        */
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
    function isSaleActive()public view returns(bool){
        return(!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    function buyTokens() public payable{
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below min purchase");
        require(msg.value <= maxPurchase, "Amount is above max purchase");
        uint256 tokenAmount = (msg.value * 10**uint256(decimals))/ tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");
        totalRaised+= msg.value;
        _transfer(address(this),msg.sender,tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
        
    }
//OVERRIDE temporarily restrict token transfers while the sale is ongoing.
    function transfer(address _to, uint256 _value)public override returns(bool){
        if(!finalized && msg.sender != address(this) && initialTransferDone){
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);
    }
//OVERRIDE 
    function transferFrom(address _from, address _to, uint256 _value)public override returns(bool){
        if(!finalized && _from != address(this)){
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public payable{
        require(msg.sender == projectOwner, "Only owner can call this function");
        require(!finalized,"Sale is already finalized");
        require (block.timestamp > saleEndTime, "Sale not finished yet");
        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];
        (bool sucess,) = projectOwner.call{value:  address(this).balance}("");
        require(sucess, "Transfer failed");
        emit SaleFinalized(totalRaised, tokensSold);
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
        buyTokens();
    }
    }






