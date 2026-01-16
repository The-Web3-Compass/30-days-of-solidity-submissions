// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day12-SimpleERC20.sol";

contract SimplifiedTokenSale is SimpleERC20{
    uint256 public tokenPrice;// 1 token = ? ETH
    // 发售时间起末
    uint256 public saleStartTime;
    uint256 public  saleEndTime;
    uint256 public minPurchase;//允许单笔购买的最小ETH对应的token
    uint256 public maxPurchase;
    
    uint256 public totalRasied;//卖出后得到的以太币
    address public endedAccount;//发售结束后收到的钱的账户

    bool public finalized = false;
    bool private initialTransferDone = false;//确保合约转账前已收到所有代币，意思是这个合约专门用来发售代币，所以原合约账户的代币就被转到这里

    event tokenPurchased(address indexed _buyer, uint256 _ethAmount, uint256 _tokenAmount);
    event saleFinalized(uint256 _totalRasied,uint _totalTokenSold);//卖出多少

    constructor (
        uint256 _initalSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationSeconds,
        uint256 _maxPurchase,
        uint256 _minPurchase,
        address _projectOwner
    )SimpleERC20(_initalSupply){
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        endedAccount = _projectOwner;
        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;//从部署者那里转移了所有代币
    }

    function isSaleActive() public view returns (bool){
        return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    function buyTokens() public payable {
        require(isSaleActive(), "Not TimeDuration!");
        require(msg.value >= minPurchase, "too low");
        require(msg.value <= maxPurchase, "too high");

        uint256 tokenAmount = (msg.value*10**uint256(decimals))/tokenPrice;
        
        require(balanceOf[address(this)] >= tokenAmount, "Insufficient token!");
         totalRasied += msg.value;
         _transfer(address(this), msg.sender, tokenAmount);//转移代币
         emit tokenPurchased(msg.sender, msg.value, tokenAmount);
    } 
    // 重写转账逻辑 防止在发行期间进行代币的转移
    function transfer(address _to, uint256 _value) public override {
        // 判断是否可以转账
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            require(false, "locked time");
            }

        // 转账
        super.transfer( _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public override {
        // 判断是否可以转账
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            require(false, "locked time");
            }

        // 转账
        super.transferFrom(_from, _to, _value);( _to, _value);
    }
    // 结束代币发售
    function finalizeSale() public payable{
        //只有endedAccount账户可以结束发售
        require(msg.sender==endedAccount, "No permisssion");
        require(!finalized, "already finalized");
        require(block.timestamp >= saleEndTime, "Not finalized");
        finalized = true;

        uint256 tokenSold = totalSupply - balanceOf[address(this)];
        (bool success,)=endedAccount.call{value:address(this).balance}("");
        require(success,"Transfer to EndAccount is failed");
        emit saleFinalized(totalRasied, tokenSold);

    }
    //还有多久发行结束
    function timeRemaining() public view returns(uint256){
        if(block.timestamp >= saleEndTime){
            return 0;
        }
        return saleEndTime-block.timestamp;
    }
    //可购买代币还剩多少
    function tonkenRemain() public view returns(uint256){
        return balanceOf[address(this)];
    }

    //如果有人不购买代币，直接转账
    receive() external payable {
        buyTokens();
     }



}