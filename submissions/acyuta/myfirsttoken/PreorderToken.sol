// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SimpleERC20.sol";

contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    address public projectOwner;
    bool public finalized = false;

    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        address _projectOwner
    ) SimpleERC20(_initialSupply) {
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        projectOwner = _projectOwner;
        
        // Move all tokens to this contract so it can sell them
        _transfer(msg.sender, address(this), totalSupply);
    }

    // 1. BUYING MECHANISM
    function buyTokens() public payable {
        require(!finalized && block.timestamp <= saleEndTime, "Sale inactive");
        
        // Calculate amount: (ETH sent * decimals) / price
        uint256 tokenAmount = (msg.value * 10**uint256(decimals)) / tokenPrice;
        
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // 2. LOCKING MECHANISM (Inheritance Magic!)
    // We override the transfer function of the parent ERC20.
    function transfer(address _to, uint256 _value) public override returns (bool) {
        // Only allow transfers if the sale is finalized OR if the contract itself is sending (for buying)
        require(finalized || msg.sender == address(this), "Tokens locked");
        return super.transfer(_to, _value);
    }

    // 3. WITHDRAWAL
    function finalizeSale() public {
        require(msg.sender == projectOwner && block.timestamp > saleEndTime, "Cannot finalize");
        finalized = true; // Unlocks transfers!
        payable(projectOwner).transfer(address(this).balance);
    }

    // Allow receiving ETH directly
    receive() external payable { buyTokens(); }
}