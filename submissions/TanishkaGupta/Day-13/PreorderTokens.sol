// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PreorderTokens {

    string public name = "PreorderToken";
    string public symbol = "POT";
    uint8 public decimals = 18;

    uint public totalSupply;
    uint public rate = 100; // 1 Ether = 100 tokens

    address public owner;

    mapping(address => uint) public balanceOf;

    event TokensPurchased(address indexed buyer, uint etherSpent, uint tokensReceived);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor(uint _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10 ** uint(decimals);
        balanceOf[address(this)] = totalSupply; // tokens stored in contract for sale
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    // Buy tokens by sending Ether
    function buyTokens() public payable {

        require(msg.value > 0, "Send Ether to buy tokens");

        uint tokensToBuy = msg.value * rate;

        require(balanceOf[address(this)] >= tokensToBuy, "Not enough tokens available");

        balanceOf[address(this)] -= tokensToBuy;
        balanceOf[msg.sender] += tokensToBuy;

        emit TokensPurchased(msg.sender, msg.value, tokensToBuy);
        emit Transfer(address(this), msg.sender, tokensToBuy);
    }

    // Owner withdraws collected Ether
    function withdrawEther() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Check contract token balance
    function tokensRemaining() public view returns (uint) {
        return balanceOf[address(this)];
    }
}