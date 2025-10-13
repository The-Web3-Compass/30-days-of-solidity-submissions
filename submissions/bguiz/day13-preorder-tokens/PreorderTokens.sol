// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { Ownable } from "./Ownable.sol";
import { MyFirstToken } from "./MyFirstToken.sol";

/**
 * @title PreorderTokens
 * @dev Let's make your own digital currency!
 * You'll create a basic token that can be transferred between users, implementing the ERC20 standard.
 * It's like creating your own in-game money, demonstrating how to create and manage tokens.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 13
 */
contract PreorderTokens is MyFirstToken, Ownable {
    event Withdrawal(address to, uint256 amount);

    uint256 public tokenPrice;
    uint256 public startSale;
    uint256 public endSale;
    uint256 public minAmount;
    uint256 public maxAmount;

    constructor(
        uint256 initialSupply,
        uint256 duration,
        uint256 price,
        uint256 minSale,
        uint256 maxSale
    ) MyFirstToken() Ownable() {
        _mint(address(this), initialSupply);
        startSale = block.timestamp;
        endSale = startSale + duration;
        tokenPrice = price;
        minAmount = minSale;
        maxAmount = maxSale;
    }

    function forSale() public view returns(bool) {
        return (block.timestamp >= startSale && block.timestamp <= endSale);
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(forSale(), "sale is not currently active");
        require(block.timestamp >= startSale && block.timestamp <= endSale, "outside of sale period");
        uint256 numTokens = msg.value / tokenPrice;
        require(balanceOf(address(this)) >= numTokens, "not enough tokens remaining");
        _transfer(address(this), msg.sender, numTokens);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(!forSale(), "transfers are not allowed during sale");
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(!forSale(), "transfers are not allowed during sale");
        return super.transferFrom(from, to, value);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "zero baance to withdraw");
        require(!forSale(), "withdrawal not allowed during sale");
        (bool transferSuccess,) = owner.call{ value: amount }("");
        require(transferSuccess, "withdrawal transfer failed");
        emit Withdrawal(owner, amount);
    }
}
