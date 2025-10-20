// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day13 LockableERC20.sol"; // 导入我们更新后的基础代币合约


contract SimplifiedTokenSale is LockableERC20 {

    // --- 销售状态变量 ---
    uint256 public immutable tokenPrice; // 每个代币的ETH价格 (以 wei 为单位), 设置后不可更改
    uint256 public immutable saleEndTime; // 销售结束的时间戳
    uint256 public minPurchase; // 最小购买额 (ETH in wei)
    uint256 public maxPurchase; // 最大购买额 (ETH in wei)

    uint256 public ethRaised;
    uint256 public tokensSold;
    bool public saleActive;

    // --- 事件 ---
    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event SaleFinalized(uint256 totalEthRaised);

    /**
     * @dev 构造函数，初始化代币和销售参数。
     * @param _price 每个代币的价格 (in wei)。
     * @param _saleDuration 销售持续时间 (秒)。
     * @param _minPurchaseETH 最小购买额 (in wei)。
     * @param _maxPurchaseETH 最大购买额 (in wei)。
     * @param _initialSupply 用于销售的代币总量。
     */
    constructor(
        uint256 _price,
        uint256 _saleDuration,
        uint256 _minPurchaseETH,
        uint256 _maxPurchaseETH,
        uint256 _initialSupply
    ) LockableERC20("Sale Token", "STK", 0) { // 父合约初始供应为0
        require(_price > 0, "Price must be > 0");
        require(_maxPurchaseETH >= _minPurchaseETH, "Max purchase must be >= min");

        tokenPrice = _price;
        saleEndTime = block.timestamp + _saleDuration;
        minPurchase = _minPurchaseETH;
        maxPurchase = _maxPurchaseETH;

        // 铸造代币并将其存入本合约地址以供销售
        uint256 scaledSupply = _initialSupply * (10**decimals); // <- 已修复：移除了括号
        totalSupply = scaledSupply;
        balanceOf[address(this)] = scaledSupply;
        emit Transfer(address(0), address(this), scaledSupply);

        // 激活销售并锁定常规转账
        saleActive = true;
        transfersLocked = true;
    }

    /**
     * @dev 重写父合约的钩子函数，定义销售期间的特殊转账规则。
     */
    function _beforeTokenTransfer(address from, address to, uint256 value) internal view override {
        // 如果销售处于激活状态...
        if (saleActive) {
            // ...只允许代币从本合约地址转出 (即卖给买家)
            require(from == address(this), "TokenSale: Transfers are restricted during sale");
        } else {
            // 如果销售已结束，则回退到父合约的默认逻辑 (检查 `transfersLocked` 标志)
            super._beforeTokenTransfer(from, to, value);
        }
    }

    /**
     * @dev 核心购买函数。
     */
    function buyTokens() public payable {
        // 1. 检查销售是否激活
        require(saleActive, "TokenSale: Sale is not active");
        require(block.timestamp < saleEndTime, "TokenSale: Sale has ended");

        // 2. 强制执行最小和最大购买限制
        require(msg.value >= minPurchase, "TokenSale: ETH sent is below minimum purchase");
        require(msg.value <= maxPurchase, "TokenSale: ETH sent is above maximum purchase");

        // 3. 计算要发送的代币数量
        uint256 tokensToBuy = msg.value / tokenPrice;

        // 4. 确保合约有足够的代币库存
        require(tokensAvailable() >= tokensToBuy, "TokenSale: Not enough tokens left for sale");

        // 5. 更新已筹集的ETH和已售出的代币数量
        ethRaised += msg.value;
        tokensSold += tokensToBuy;

        // 6. 将代币转移给买家
        _transfer(address(this), msg.sender, tokensToBuy);

        emit TokensPurchased(msg.sender, msg.value, tokensToBuy);
    }
    
    /**
     * @dev 最终确定销售 (仅限所有者)。
     */
    function finalizeSale() external onlyOwner {
        require(saleActive, "TokenSale: Sale is not active or already finalized");
        require(block.timestamp >= saleEndTime, "TokenSale: Sale has not ended yet");

        // 1. 标记销售为不激活
        saleActive = false;
        // 2. 解锁代币转账功能
        unlock();

        // 3. 将筹集到的ETH发送给项目所有者
        (bool success, ) = owner.call{value: ethRaised}("");
        require(success, "TokenSale: Failed to withdraw ETH");

        emit SaleFinalized(ethRaised);
    }

    // --- 视图 (View) 函数 ---

    /**
     * @return 剩余可供销售的代币数量。
     */
    function tokensAvailable() public view returns (uint256) {
        return balanceOf[address(this)];
    }

    /**
     * @return 销售剩余时间 (秒)。
     */
    function timeRemaining() public view returns (uint256) {
        if (saleActive && block.timestamp < saleEndTime) {
            return saleEndTime - block.timestamp;
        }
        return 0;
    }

    // --- 回退函数 ---
    /**
     * @dev 允许合约直接接收ETH并触发购买。
     */
    receive() external payable {
        buyTokens();
    }
}
