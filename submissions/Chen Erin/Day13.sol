// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract SimpleERC20 {
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ✅ 加上 virtual，允许子合约重写这些函数
    function transfer(address _to, uint256 _value) public virtual returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}



contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice;        // 每个代币的价格 (wei)
    uint256 public saleStartTime;     // 开始时间
    uint256 public saleEndTime;       // 结束时间
    uint256 public minPurchase;       // 最小购买额度 (wei)
    uint256 public maxPurchase;       // 最大购买额度 (wei)
    uint256 public totalRaised;       // 已筹集的 ETH
    address public projectOwner;      // 项目方地址
    bool public finalized = false;    // 是否已结束
    bool private initialTransferDone = false; // 初始代币是否已转入合约

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

        // 将全部代币转移至当前合约，作为待售代币池
        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;
    }

    // 🔹 判断发售是否进行中
    function isSaleActive() public view returns (bool) {
        return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    // 🔹 购买代币函数
    function buyTokens() public payable {
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Below min purchase");
        require(msg.value <= maxPurchase, "Exceeds max purchase");

        uint256 tokenAmount = (msg.value * 10 ** uint256(decimals)) / tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // 🔹 锁定发售期内的转账
    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            revert("Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);
    }

    // 🔹 锁定发售期内的委托转账
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if (!finalized && _from != address(this)) {
            revert("Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    // 🔹 发售结束
    function finalizeSale() public payable {
        require(msg.sender == projectOwner, "Only owner");
        require(!finalized, "Already finalized");
        require(block.timestamp > saleEndTime, "Sale not ended");

        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];

        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");

        emit SaleFinalized(totalRaised, tokensSold);
    }

    // 🔹 剩余时间（秒）
    function timeRemaining() public view returns (uint256) {
        if (block.timestamp >= saleEndTime) {
            return 0;
        }
        return saleEndTime - block.timestamp;
    }

    // 🔹 剩余可购买代币数量
    function tokensAvailable() public view returns (uint256) {
        return balanceOf[address(this)];
    }

    // 🔹 允许直接发送 ETH 自动购买
    receive() external payable {
        buyTokens();
    }
}