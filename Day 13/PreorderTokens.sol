// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PreorderTokens {
    string public name = "PreorderToken";
    string public symbol = "POT";
    uint8 public decimals = 18;
    uint public totalSupply;
    uint public rate = 1000; // 1 ETH = 1000 POT
    address public owner;

    mapping(address => uint) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint value);
    event TokensPurchased(address indexed buyer, uint amountSpent, uint tokensBought);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * (10 ** uint(decimals));
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    //  Buy tokens by sending Ether
    function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        uint tokensToBuy = msg.value * rate;
        require(balanceOf[owner] >= tokensToBuy, "Not enough tokens left");

        balanceOf[owner] -= tokensToBuy;
        balanceOf[msg.sender] += tokensToBuy;

        emit Transfer(owner, msg.sender, tokensToBuy);
        emit TokensPurchased(msg.sender, msg.value, tokensToBuy);
    }


    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // View contract’s ETH balance
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
}
