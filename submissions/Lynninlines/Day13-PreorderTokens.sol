// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract PreorderTokens {
    address public owner;
    uint256 public tokensPerEth;
    mapping(address => uint256) public tokenBalance;

    constructor() {
        owner = msg.sender;
        tokensPerEth = 100;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(msg.value > 0);
        uint256 tokens = msg.value * tokensPerEth;
        tokenBalance[msg.sender] += tokens;
    }

    function withdrawEther() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        tokensPerEth = newPrice;
    }
}
