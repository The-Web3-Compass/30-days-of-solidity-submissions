// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PreorderTokens is ERC20, Ownable {
    uint256 public rate; // tokens per Ether
    uint256 public totalRaised;
    bool public saleActive;

    event TokensPurchased(address indexed buyer, uint256 amountSpent, uint256 tokensBought);
    event SaleStatusChanged(bool active);

    constructor(uint256 _rate) ERC20("Preorder Token", "PDT") Ownable(msg.sender) {
        require(_rate > 0, "Rate must be greater than 0");
        rate = _rate;
        saleActive = true;

        // Mint 1,000,000 tokens to the contract for sale
        _mint(address(this), 1_000_000 * 10 ** decimals());
    }

    function buyTokens() external payable {
        require(saleActive, "Sale not active");
        require(msg.value > 0, "Must send Ether");

        uint256 tokensToBuy = msg.value * rate;
        require(balanceOf(address(this)) >= tokensToBuy, "Not enough tokens left");

        totalRaised += msg.value;
        _transfer(address(this), msg.sender, tokensToBuy);

        emit TokensPurchased(msg.sender, msg.value, tokensToBuy);
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function toggleSale(bool _status) external onlyOwner {
        saleActive = _status;
        emit SaleStatusChanged(_status);
    }

    function setRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Rate must be greater than 0");
        rate = _newRate;
    }

    function remainingTokens() external view returns (uint256) {
        return balanceOf(address(this));
    }
}
