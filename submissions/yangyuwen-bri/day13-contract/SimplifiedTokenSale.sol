//SPDX-License-Identifier:MTI
pragma solidity ^0.8.20;
import "submissions/yangyuwen-bri/day12-contract/SimpleERC20.sol";

contract SimplifiedTokenSale is SimpleERC20{
    
    uint256 public tokenPrice;
    uint256 public saleStarTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised; //筹集到的ETH总额
    address public projectOwner;
    bool public finalized = false;
    bool private initialTransferDone = false; //内部控制：确保在初始代币转移后才锁定转账功能

    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokenSold);

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice, //wei
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) SimpleERC20(_initialSupply){
        //设置销售规则
        tokenPrice = _tokenPrice;
        saleStarTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        //把所有代币从部署者转移到本合约:address(this)
        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;

    }

    function isSaleActivate() public view returns(bool){
        return(!finalized && block.timestamp >= saleStarTime && block.timestamp <= saleEndTime);
    }

    function buyTokens() public payable{
        
        require(isSaleActivate(), "sale is not activate.");
        require(msg.value >= minPurchase && msg.value <= maxPurchase, "invalid amount.");

        uint256 tokenAmount = (msg.value * 10 **uint256(decimals)) / tokenPrice;
        require(balance0f[address(this)] >= tokenAmount, "not enough tokens left for sale.");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);

    }

    function transfer(address _to, uint256 _value) public override returns(bool){
        if(!finalized && msg.sender!=address(this) && initialTransferDone){
            require(false, "tokens are locked until sale is finalized.");
        }
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns(bool){
        if(!finalized && _from != address(this)){
            require(false, "tokens are locked until sale is finalized.");
        }
        return super.transferFrom(_from, _to, _value);
    }

    function finalizeSale() public payable{
        
        require(msg.sender == projectOwner, "only owner can call the function.");
        require(!finalized, "sale already finalized.");
        require(block.timestamp >= saleEndTime, "sale not finished yet.");

        finalized = true;

        uint256 tokenSold = totalSupply - balance0f[address(this)];

        (bool success, ) = projectOwner.call{value:address(this).balance}("");
        require(success, "transfer to project owner failed.");

        emit SaleFinalized(totalRaised, tokenSold);
        
    }

    function timeRemaining() public view returns(uint256){
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return saleEndTime - block.timestamp;
    }
    function tokensAvailable() public view returns(uint256){
        return balance0f[address(this)];
    }


}