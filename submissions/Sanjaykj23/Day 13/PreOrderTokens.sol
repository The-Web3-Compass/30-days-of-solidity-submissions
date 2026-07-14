pragma solidity ^0.8.10;
import "../Day 12/ERC20.sol";
contract PreorderToken is SimpleERC20 {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;
    address public projectOwner;
    bool public finalized = false;
    bool private initialTransferDone = false;
    uint256 tokenRaised = 0;
    constructor(
        uint _initialSupply,
        uint _tokenPrice,
        uint _duration,
        uint _minPrice,
        uint _maxPrice,
        address _owner
    ) SimpleERC20(_initialSupply) {
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _duration;
        minPurchase = _minPrice;
        maxPurchase = _maxPrice;
        projectOwner = _owner;
        _transfer(msg.sender, address(this), _tokenPrice);
        initialTransferDone = true;
    }
    function isSalesActive() public view returns (bool) {
        if (block.timestamp < saleEndTime) {
            return true;
        } else {
            return false;
        }
    }
    function buyTokens() public payable{
        require(isSalesActive(), "Sales End");
        require(msg.value >= minPurchase, "Amount is below minimum purchase");
        require(msg.value <= maxPurchase, "Amount exceeds maximum purchase");
        uint256 tokenAmount = (msg.value * 10 ** uint256(decimals)) /
            tokenPrice;
        require(
            balanceOf[address(this)] >= tokenAmount,
            "Not enough tokens left for sale"
        );
        tokenRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);
    }

    function transfer(
        address _to,
        uint256 _value
    ) public override returns (bool) {
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);
    }
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        if (!finalized && _from != address(this)) {
            require(false, "Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }
    function finalizeSales() public {
        require(msg.sender == projectOwner, "No acess");
        require(!finalized, "Already ENded!");
        require(block.timestamp > saleEndTime, "Sales not end!");
        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];

        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "Transfer to project owner failed");
    }
}
