// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../myfirsttoken-contract/code/SimpleERC20.sol";

contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    address public projectOwner;
    bool public finalized = false;

    event TokenPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);

   constructor(
    uint256 _initialSupply,
    uint256 _tokenPrice,
    uint256 _saleDurationInSeconds,
    address _projector
   ) SimpleERC20(_initialSupply) {
    tokenPrice = _tokenPrice;
    salesStartTime = block.timestamp;
    salesEndTime = block.timestamp + _saleDurationInSeconds;
    projectOwner = _projectOwner;

     // Move all tokens to this contract so it can sell them
        // Note: In constructor, msg.sender is deployer. SimpleERC20 assigns initial supply to msg.sender.
        // We transfer from msg.sender to address(this).
        // However, SimpleERC20 logic in constructor sets balanceOf[msg.sender] = totalSupply.
        // So we need to manually adjust here if we want the contract to hold them, 
        // OR we just transfer them. Since we inherit, we can just manipulate state or call _transfer.
        // But let's follow the walkthrough logic which assumes standard behavior.
        // Since we are inside the constructor of the child, the parent constructor runs first.
        // So balanceOf[msg.sender] has the tokens.
        _transfer(msg.sender, address(this), totalSupply);
   }

 // 1. BUYING MECHANISM
 function buyTokens() public payable {
    require(!finalized && block.timestamp <= saleEndTime, "Sale inactive");

   // Calculate amount: (ETH sent * decimals) / tokenPrice
   uint256 tokenAmount = (msg.value * 10**uint256(decimals)) / tokenPrice; 

   _transfer(address(this), msg.sender, tokenAmount);
   emit TokensPurchased(msg.sender, msg.value, tokenAmount);
 }

 // 2. LOCKING MECHANISM (Inheritance Magic!)
    // We override the transfer function of the parent ERC20.

    function transfer(address _to, uint256 _value) public override returns (bool) {
      // 2. LOCKING MECHANISM (Inheritance Magic!)
    // We override the transfer function of the parent ERC20.
      require(finalized || msg.sender == address(this), "Tokens locked");
      return super.transfer(_to, _value);
    }

 // Also override transferFrom to be safe, although walkthough didn't explicitly mention it, it's good practice.
 function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(finalized || msg.sender == address(this), "Tokens locked");
    return super.transferFrom(_from, _to, _value);
 }

  // 3. WITHDRAWAL
  function finalizeSale() public {
    require(msg.sender == projectOwner && block.timestamp > saleEndTime, "Cannot finalize");
    finalized = true; // Unlocks transfer!
    payable(projectOwner).transfer(address(this).balance);
  }

  // Allow receiving ETH directly
  recieve() external payable { buyTokens(); }
}