// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./Day12.sol";
contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice;//每个代币值多少 ETH（单位是 wei，1 ETH = 10¹⁸ wei）
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalRaised;//目前为止接收的 ETH总额
    address public projectOwner;//发售结束后接收 ETH 的钱包地址
    bool public finalized = false;
    bool private initialTransferDone = false;//用于确保合约在锁定转账前已收到所有代币

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

    // 将所有代币转移至此合约用于发售
    _transfer(msg.sender, address(this), totalSupply);

    // 标记我们已经从部署者那里转移了代币
    initialTransferDone = true;
}

    function isSaleActive() public view returns (bool) {
    return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
}//用来检查发售是否正在进行

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

    function transfer(address _to, uint256 _value) public override returns (bool) {
    if (!finalized && msg.sender != address(this) && initialTransferDone) {
        require(false, "Tokens are locked until sale is finalized");
    }
    return super.transfer(_to, _value);//super调用父合约

}

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
        //此处把发售期间筹集到的全部 ETH 转给  projectOwner。
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