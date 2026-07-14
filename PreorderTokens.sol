// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PreorderToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    uint256 public rate;
    uint256 public saleSupply;
    uint256 public tokensSold;
    uint256 public startTime;
    uint256 public endTime;

    event TokensPurchased(address indexed buyer, uint256 amountETH, uint256 tokens);
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event SaleTimeUpdated(uint256 newStart, uint256 newEnd);
    event SaleSupplyUpdated(uint256 oldSupply, uint256 newSupply);
    event Withdrawn(address indexed to, uint256 amountETH);
    event UnsoldWithdrawn(address indexed to, uint256 amountTokens);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        uint256 rate_,
        uint256 saleSupply_,
        uint256 startTime_,
        uint256 endTime_
    ) ERC20(name_, symbol_) {
        require(rate_ > 0, "rate > 0");
        require(endTime_ == 0 || endTime_ > startTime_, "invalid time window");
        rate = rate_;
        saleSupply = saleSupply_;
        startTime = startTime_;
        endTime = endTime_;
        if (initialSupply_ > 0) _mint(msg.sender, initialSupply_);
    }

    function buyTokens() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Send ETH");
        if (startTime != 0) require(block.timestamp >= startTime, "Not started");
        if (endTime != 0) require(block.timestamp <= endTime, "Ended");

        uint256 tokens = (msg.value * rate) / 1 ether;
        require(tokens > 0, "Too small");
        require(tokensSold + tokens <= saleSupply, "Sold out");
        require(balanceOf(address(this)) >= tokens, "No tokens");

        tokensSold += tokens;
        _transfer(address(this), msg.sender, tokens);
        emit TokensPurchased(msg.sender, msg.value, tokens);
    }

    function setRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "rate > 0");
        emit RateUpdated(rate, newRate);
        rate = newRate;
    }

    function setSaleTimes(uint256 newStart, uint256 newEnd) external onlyOwner {
        require(newEnd == 0 || newEnd > newStart, "invalid times");
        startTime = newStart;
        endTime = newEnd;
        emit SaleTimeUpdated(newStart, newEnd);
    }

    function setSaleSupply(uint256 newSaleSupply) external onlyOwner {
        require(newSaleSupply >= tokensSold, "too low");
        emit SaleSupplyUpdated(saleSupply, newSaleSupply);
        saleSupply = newSaleSupply;
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function withdrawEther(address payable to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "invalid address");
        uint256 bal = address(this).balance;
        require(amount <= bal, "insufficient balance");
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
        emit Withdrawn(to, amount);
    }

    function withdrawAllEther(address payable to) external onlyOwner {
        withdrawEther(to, address(this).balance);
    }

    function withdrawUnsoldTokens(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "invalid address");
        uint256 unsold = saleSupply - tokensSold;
        require(amount <= unsold, "too high");
        _transfer(address(this), to, amount);
        emit UnsoldWithdrawn(to, amount);
    }

    receive() external payable {}
    fallback() external payable {}
}
