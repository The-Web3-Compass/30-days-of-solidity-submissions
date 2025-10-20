// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address payable public owner;
    
    uint256 public usdToEthRate = 0.0005 ether;
    uint256 public eurToEthRate = 0.0006 ether;
    
    struct Contributor {
        uint256 ethTips;
        uint256 usdTips;
        uint256 eurTips;
        uint256 lastTipTimestamp;
    }
    
    mapping(address => Contributor) public contributors;
    
    event TipReceived(
        address indexed sender, 
        string currency, 
        uint256 amount, 
        uint256 ethValue,
        string message
    );
    event RateUpdated(string currency, uint256 newRate);
    event Withdrawal(address indexed owner, uint256 amount);
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    receive() external payable {
        _processTip(msg.value, "ETH", "");
    }
    
    function _processTip(uint256 amount, string memory currency, string memory message) private {
        require(amount > 0, "Tip amount must be > 0");
        
        Contributor storage contributor = contributors[msg.sender];
        
        if (keccak256(bytes(currency)) == keccak256(bytes("ETH"))) {
            contributor.ethTips += amount;
        } else if (keccak256(bytes(currency)) == keccak256(bytes("USD"))) {
            contributor.usdTips += amount;
        } else if (keccak256(bytes(currency)) == keccak256(bytes("EUR"))) {
            contributor.eurTips += amount;
        }
        
        contributor.lastTipTimestamp = block.timestamp;
        
        uint256 ethValue = amount;
        if (keccak256(bytes(currency)) == keccak256(bytes("USD"))) {
            ethValue = amount * usdToEthRate;
        } else if (keccak256(bytes(currency)) == keccak256(bytes("EUR"))) {
            ethValue = amount * eurToEthRate;
        }
        
        emit TipReceived(msg.sender, currency, amount, ethValue, message);
    }
    
    function sendEthTip(string memory message) external payable {
        require(msg.value > 0, "Tip amount must be > 0");
        _processTip(msg.value, "ETH", message);
    }
    
    function sendUsdTip(uint256 usdAmount, string memory message) external payable {
        require(usdAmount > 0, "USD amount must be > 0");
        
        uint256 requiredEth = usdAmount * usdToEthRate;
        require(msg.value >= requiredEth, "Insufficient ETH");
        
        if (msg.value > requiredEth) {
            payable(msg.sender).transfer(msg.value - requiredEth);
        }
        
        _processTip(usdAmount, "USD", message);
    }
    
    function sendEurTip(uint256 eurAmount, string memory message) external payable {
        require(eurAmount > 0, "EUR amount must be > 0");
        
        uint256 requiredEth = eurAmount * eurToEthRate;
        require(msg.value >= requiredEth, "Insufficient ETH");
        
        if (msg.value > requiredEth) {
            payable(msg.sender).transfer(msg.value - requiredEth);
        }
        
        _processTip(eurAmount, "EUR", message);
    }
    
    function updateExchangeRate(string memory currency, uint256 newRate) external onlyOwner {
        require(newRate > 0, "Rate must be positive");
        
        if (keccak256(bytes(currency)) == keccak256(bytes("USD"))) {
            usdToEthRate = newRate;
        } else if (keccak256(bytes(currency)) == keccak256(bytes("EUR"))) {
            eurToEthRate = newRate;
        } else {
            revert("Invalid currency");
        }
        
        emit RateUpdated(currency, newRate);
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        owner.transfer(balance);
        emit Withdrawal(owner, balance);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getTotalContributionInEth(address contributor) external view returns (uint256) {
        Contributor memory c = contributors[contributor];
        return (c.ethTips) + 
               (c.usdTips * usdToEthRate) + 
               (c.eurTips * eurToEthRate);
    }
    
    function getExchangeRate(string memory currency) external view returns (uint256) {
        if (keccak256(bytes(currency)) == keccak256(bytes("USD"))) {
            return usdToEthRate;
        } else if (keccak256(bytes(currency)) == keccak256(bytes("EUR"))) {
            return eurToEthRate;
        }
        revert("Invalid currency");
    }
}
