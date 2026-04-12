// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../Day12/MyToken.sol";

contract TokenPreSale is MyToken {

    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    address public projectOwner;
    bool public finalized;

    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint _decimals,
        uint _initialSupply,
        uint256 _tokenPrice,
        uint256 _duration,
        address _projectOwner
    )
        MyToken(_name, _symbol, _decimals, _initialSupply)
    {
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _duration;
        projectOwner = _projectOwner;

        // transfer(address(this), totalSupply);
        balanceOf[msg.sender] -= totalSupply;
        balanceOf[address(this)] += totalSupply;
    }

    function buyTokens() public payable {
        require(!finalized, "Sale finalized");
        require(block.timestamp <= saleEndTime, "Sale ended");
        require(msg.value > 0, "Send ETH");

        uint256 tokenAmount = (msg.value * (10 ** decimals)) / tokenPrice;

        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens");

        // transfer(msg.sender, tokenAmount);
        balanceOf[msg.sender] += tokenAmount;
        balanceOf[address(this)] -= tokenAmount;

        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    function transfer(address to, uint amount) public override returns (bool) {
        require(finalized || msg.sender == address(this), "Tokens locked");
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint amount) public override returns (bool) {
        require(finalized || msg.sender == address(this), "Tokens locked");
        return super.transferFrom(from, to, amount);
    }

    function finalizeSale() public {
        require(msg.sender == projectOwner, "Not owner");
        require(block.timestamp > saleEndTime, "Sale not ended");

        finalized = true;

        (bool success, ) = payable(projectOwner).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {
        buyTokens();
    }
}