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

        // Calculate amount: (ETH sent * decimals) / price, but with added overflow protection
        require(msg.value <= type(uint256).max / 10**decimals, "Amount too large");

        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);

    }

    // 2. LOCKING MECHANISM (Inheritance Magic!)
    // We override the transfer function of the parent ERC20
    function transfer(address _to, uint256 _value) public override returns (bool) {
        // ONLY allow transfers IF the sale is finalized OR if the contract itself is sending (for buying)
        require(fainlized || msg.sender == address(this), "Tokens locked");
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

    // TIERED PRICING (Early Bird Discount)
    function getTokenPrice() public view returns (uint256) {
        uint256 elapsed = block.timestamp - saleStartTime;

        if (elapsed < 1 days) {
            return tokenPrice * 80 / 100; // 20% discount first day
        } else if (elapsed < 3 days) {
            return tokenPrice * 90 / 100; // 10% discount next 2 days
        } else {
            return tokenPrice; // Regular price after 3 days
        }
    }

    function buyTokens() public payable {
        uint256 currentPrice = getTokenPrice();
        uint256 tokenAmount = (msg.value * 10**decimals) / currentPrice;
        _transfer(address(this), msg.sender, tokenAmount);
    }
    
    // HARD CAP (Maximum raise)
    uint256 public constant HARD_CAP = 1000 ether;
    uint256 public totalRaised;

    function buyTokens() public payable {
      require(totalRaised + msg.value <= HARD_CAP, "Hard cap reached");
     totalRaised += msg.value;
     // ... rest of logic
    }

    // WHITELIST (Private sale)
    mapping(address => bool) public whitelist;

    function addToWhitelist(address[] memory addresses) public {
        require(msg.sender == projectOwner);
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function buyTokens() public payable {
        require(whitelist[msg.sender], "Not whitelisted");
        // ... rest of logic
    }

    // VESTING SCHEDULE
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 released;
        uint256 startTime;
        uint256 duration;
    }

    mapping(address => VestingSchedule) public vesting;

    function releaseVested() public {
        VestingSchedule storage schedule = vesting[msg.sender];
            uint256 elapsed = block.timestamp - schedule.startTime;
            uint256 vested = (schedule.totalAmount * elapsed) / schedule.duration;
            uint256 releasable = vested - schedule.released;
    
        require(releasable > 0, "Nothing to release");
        schedule.released += releasable;
        _transfer(address(this), msg.sender, releasable);
    }

    // this is the SAFE way of adding REFUND functionality
    function refund() public {
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0; // Prevent re-entrancy
        payable(msg.sender).transfer(amount); // External call AFTER
    }

    // this prevents OWNER WITHDRAWAL BEFORE SALE ENDS which is quite rude
    function finalizeSale() public {
        require(msg.sender == projectOwner);
        require(block.timestamp > saleEndTime, "Sale not ended");
        finalized = true;
        payable(projectOwner).transfer(address(this).balance);
    }
}