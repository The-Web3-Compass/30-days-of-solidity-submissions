// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Day-12/simpleERC20Token.sol";

contract SimplifiedTokenSale is SimpleERC20 {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    address public projectOwner;
    bool public finalized = false;
    uint256 public constant HARD_CAP = 1000 ether;
    uint256 public totalRaised;

    mapping(address => bool) public whitelist;
    

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


    function getTokenPrice() public view returns (uint256) {
    uint256 elapsed = block.timestamp - saleStartTime;
    
    if (elapsed < 1 days) {
        return tokenPrice * 80 / 100; // 20% discount first day
    } else if (elapsed < 7 days) {
        return tokenPrice * 90 / 100; // 10% discount first week
    } else {
        return tokenPrice; // Full price
    }
}
  function addToWhitelist(address[] memory addresses) public {
    require(msg.sender == projectOwner);
    for (uint i = 0; i < addresses.length; i++) {
        whitelist[addresses[i]] = true;
    }
}

    // 1. BUYING MECHANISM
    function buyTokens() public payable {
        require(whitelist[msg.sender], "You are not whitelisted");
        require(!finalized && block.timestamp <= saleEndTime, "Sale inactive");
        require(totalRaised + msg.value <= HARD_CAP, "Hard cap reached");
        
        totalRaised += msg.value;
        // Calculate amount: (ETH sent * decimals) / price

        uint256 currentPrice = getTokenPrice();
        uint256 tokenAmount = (msg.value * 10**decimals) / currentPrice;

        require(balanceOf[address(this)] >= tokenAmount, "Not enough tokens left");

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
        (bool success, ) = payable(projectOwner).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    // Allow receiving ETH directly
    receive() external payable { buyTokens(); }
}