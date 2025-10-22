// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 基础ERC-20合约，支持函数重写
contract SimpleERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply, string memory _name, string memory _symbol) {
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        name = _name;
        symbol = _symbol;
    }

    // 标记为virtual以允许重写
    function transfer(address _to, uint256 _value) public virtual returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // 标记为virtual以允许重写
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool) {
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Transfer to the zero address");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
}

// 预售合约，继承并扩展ERC-20
contract PreorderTokens is SimpleERC20 {
    uint256 public tokenPrice;          // 每个代币的ETH价格(wei)
    uint256 public saleStartTime;       // 销售开始时间戳
    uint256 public saleEndTime;         // 销售结束时间戳
    uint256 public minPurchase;         // 最小购买ETH数量(wei)
    uint256 public maxPurchase;         // 最大购买ETH数量(wei)
    uint256 public totalRaised;         // 已筹集ETH总量
    address public projectOwner;        // 项目所有者地址
    bool public finalized = false;      // 销售是否已结束
    bool private initialTransferDone = false;  // 初始代币转移标记

    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalRaised, uint256 totalTokensSold);

    constructor(
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) SimpleERC20(_initialSupply, _name, _symbol) {
        require(_tokenPrice > 0, "Token price must be greater than 0");
        require(_saleDurationInSeconds > 0, "Sale duration must be greater than 0");
        require(_minPurchase > 0, "Minimum purchase must be greater than 0");
        require(_maxPurchase >= _minPurchase, "Max purchase must be >= min purchase");
        require(_projectOwner != address(0), "Invalid project owner address");

        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        projectOwner = _projectOwner;

        // 将所有代币转移到合约地址用于销售
        _transfer(msg.sender, address(this), totalSupply);
        initialTransferDone = true;
    }

    // 检查销售是否活跃
    function isSaleActive() public view returns (bool) {
        return (!finalized && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime);
    }

    // 购买代币函数
    function buyTokens() public payable {
        require(isSaleActive(), "Sale is not active");
        require(msg.value >= minPurchase, "Amount is below minimum purchase");
        require(msg.value <= maxPurchase, "Amount exceeds maximum purchase");

        // 计算可购买的代币数量
        uint256 tokenAmount = (msg.value * 10 **uint256(decimals)) / tokenPrice;
        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left for sale");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // 重写transfer函数，在销售期间锁定代币转移
    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (!finalized && msg.sender != address(this) && initialTransferDone) {
            revert("Tokens are locked until sale is finalized");
        }
        return super.transfer(_to, _value);
    }

    // 重写transferFrom函数，在销售期间锁定授权转移
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if (!finalized && _from != address(this)) {
            revert("Tokens are locked until sale is finalized");
        }
        return super.transferFrom(_from, _to, _value);
    }

    // 结束销售并将筹集的ETH转移给项目所有者
    function finalizeSale() public {
        require(msg.sender == projectOwner, "Only owner can call this function");
        require(!finalized, "Sale already finalized");
        require(block.timestamp > saleEndTime, "Sale not finished yet");

        finalized = true;
        uint256 tokensSold = totalSupply - balanceOf[address(this)];

        // 转移所有ETH给项目所有者
        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "Transfer to project owner failed");

        emit SaleFinalized(totalRaised, tokensSold);
    }

    // 获取剩余销售时间(秒)
    function timeRemaining() public view returns (uint256) {
        if (block.timestamp >= saleEndTime) {
            return 0;
        }
        return saleEndTime - block.timestamp;
    }

    // 获取可购买的代币数量
    function tokensAvailable() public view returns (uint256) {
        return balanceOf[address(this)];
    }

    // 接收ETH时自动调用购买函数
    receive() external payable {
        buyTokens();
    }
}