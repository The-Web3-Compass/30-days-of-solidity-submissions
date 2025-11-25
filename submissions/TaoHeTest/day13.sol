// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PreorderToken is ERC20, Ownable {
    bool public saleFinalized = false;
    uint256 public saleStart;
    uint256 public saleEnd;
    uint256 public tokenPrice; // 单位：wei/代币
    uint256 public minPurchase;
    uint256 public maxPurchase;
    address public treasury;

    mapping(address => uint256) public contributions;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 price_,
        uint256 min_,
        uint256 max_,
        uint256 start_,
        uint256 end_,
        address treasury_
    ) ERC20(name_, symbol_) {
        require(start_ < end_, "开始时间必须早于结束时间");
        require(treasury_ != address(0), "无效的资金地址");

        tokenPrice = price_;
        minPurchase = min_;
        maxPurchase = max_;
        saleStart = start_;
        saleEnd = end_;
        treasury = treasury_;

        _mint(address(this), totalSupply_); // 预售合约自己持有所有代币
    }

    function buyTokens() external payable {
        require(block.timestamp >= saleStart, "预售尚未开始");
        require(block.timestamp <= saleEnd, "预售已结束");
        require(msg.value >= minPurchase, "少于最小购买额度");
        require(contributions[msg.sender] + msg.value <= maxPurchase, "超过最大购买额度");

        uint256 tokensToSend = (msg.value * (10 ** decimals())) / tokenPrice;
        require(balanceOf(address(this)) >= tokensToSend, "代币不足");

        contributions[msg.sender] += msg.value;
        _transfer(address(this), msg.sender, tokensToSend);
    }

    function finalizeSale() external onlyOwner {
        require(block.timestamp > saleEnd, "预售尚未结束");
        require(!saleFinalized, "已完成");

        saleFinalized = true;

        // 将ETH发送给项目方
        payable(treasury).transfer(address(this).balance);
    }

    // 阻止预售期间代币转账（包括买家之间）
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (!saleFinalized) {
            require(from == address(0) || to == address(0), "预售期间禁止转账");
        }
    }

    // 后门（可选）: 如果最终要收回未售出的代币
    function reclaimUnsoldTokens() external onlyOwner {
        require(saleFinalized, "仅售后可操作");
        _transfer(address(this), treasury, balanceOf(address(this)));
    }
}