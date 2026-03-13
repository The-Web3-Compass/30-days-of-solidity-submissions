// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SimpleERC20.sol";

contract PreorderTokens is SimpleERC20 {
    uint256 public tokenPrice;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    address public projectOwner;
    bool public finalized = false;

    uint256 public constant HARD_CAP = 1000 ether;
    uint256 public constant SOFT_CAP = 100 ether;
    uint256 public totalRaised;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public contributions;

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 released;
        uint256 startTime;
        uint256 duration;
    }

    mapping(address => VestingSchedule) public vesting;

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
        
        _transfer(msg.sender, address(this), totalSupply);
    }

    function getTokenPrice() public view returns (uint256) {
        uint256 elapsed = block.timestamp - saleStartTime;
        
        if (elapsed < 1 days) {
            return tokenPrice * 80 / 100;
        } else if (elapsed < 7 days) {
            return tokenPrice * 90 / 100;
        } else {
            return tokenPrice;
        }
    }

    function addToWhitelist(address[] memory addresses) public {
        require(msg.sender == projectOwner);
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function addVestingSchedule(address teamMember, uint256 amount, uint256 duration) public {
        require(msg.sender == projectOwner);
        require(vesting[teamMember].totalAmount == 0);
        vesting[teamMember] = VestingSchedule(amount, 0, block.timestamp, duration);
    }

    function buyTokens() public payable {
        require(!finalized && block.timestamp <= saleEndTime);
        require(whitelist[msg.sender]);
        require(totalRaised + msg.value <= HARD_CAP);
        
        uint256 currentPrice = getTokenPrice();
        uint256 tokenAmount = (msg.value * 10**uint256(decimals)) / currentPrice;
        
        totalRaised += msg.value;
        contributions[msg.sender] += msg.value;
        
        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    function releaseVested() public {
        VestingSchedule storage schedule = vesting[msg.sender];
        uint256 elapsed = block.timestamp - schedule.startTime;
        uint256 vested = (schedule.totalAmount * elapsed) / schedule.duration;
        uint256 releasable = vested - schedule.released;
        
        require(releasable > 0);
        schedule.released += releasable;
        _transfer(address(this), msg.sender, releasable);
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(finalized || msg.sender == address(this));
        return super.transfer(_to, _value);
    }

    function finalizeSale() public {
        require(msg.sender == projectOwner);
        require(block.timestamp > saleEndTime);
        require(totalRaised >= SOFT_CAP);
        finalized = true;
        (bool success, ) = payable(projectOwner).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function refund() public {
        require(block.timestamp > saleEndTime);
        require(totalRaised < SOFT_CAP);
        
        uint256 amount = contributions[msg.sender];
        require(amount > 0);
        contributions[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable { 
        buyTokens(); 
    }
}
