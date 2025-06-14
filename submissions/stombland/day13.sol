pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PreorderTokens {
    IERC20 public token;
    address public owner;
    uint public rate; //per ETH = Amount of token
    uint public saleEnd; //Presale End time
    uint public totalRaised; //tokens sold
    uint public hardCap = 1000 ether; //gets 1000 tokens per ETH

    mapping(address => uint) public balances;

    constructor(IERC20 _token) {
        token = _token;
        owner = msg.sender;
        rate = 1000;
        saleEnd = block.timestamp + 5 days;
    }

    receive() external payable {
        preOrderTokens();
    }

    function preOrderTokens() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        require(block.timestamp <= saleEnd, "Sale Ended!");
        require(totalRaised + msg.value <= hardCap, "Sale cap reached");

        uint256 tokenAmount = msg.value * rate;

        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Not enough tokens"
        );

        balances[msg.sender] += tokenAmount;
        totalRaised += msg.value;
        token.transfer(msg.sender, tokenAmount);
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    function tokensSold() public view returns (uint) {
        return totalRaised * rate;
    }
}
Footer
