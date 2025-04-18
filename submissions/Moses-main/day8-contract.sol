// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract TipJar {
    address payable public creator;
    mapping (address => uint) private _tips;  // tracks the amount each individual tipped, and which creator created it for performance.
    uint256 public tipCount;   // keep track of number of tips added by everyone.
    

    constructor() {
        creator = payable(msg.sender);
    }

    modifier onlyCreator() {
        require (creator == msg.sender, "Only creator can perform this action");  // will fail if not equal to the current creator of the contract
        _; // allows access to function body
    }
    
    function getTipCount() external view returns (uint) {
        return tipCount;   /// will allow anyone to query the total number of tips added. In a real scenario, this might be used as a public API for performance/security reasons when displaying data on-chain. 
    }

    function getTipsFromAddress (address addr) external view returns (uint256) { /// will allow anyone query the total amount of tips from address addr 
        return _tips[addr];   // we are using a mapping variable to store an individual's tip and which creator added it. We can then use this in our front-end interface for performance reasons when displaying data on-chain. 
    }

    function getCreatorsTotalTips() external view returns (uint256) { /// will allow anyone to query the total amount of tips from creator(s). In a real scenario, this might be used as an API for security reasons when displaying data on-chain. 
        return _tips[msg.sender];   // we are using a mapping variable to store an individual's tip and which creator added it. We can then use this in our front-end interface for performance reasons when displaying data on-chain. 
    }

       // Direct transfer method using transfer()
    function addTip(address payable _to, uint256 _amount) public {
        require(_to != address(0), "Invalid address");
        // require(registeredFriends[_to], "Recipient not registered");
        require(_tips[msg.sender] >= _amount, "Insufficient balance");
        _tips[msg.sender] -= _amount;
        _to.transfer(_amount);
        _tips[_to]+=_amount;
    }

        // Withdraw your balance
    function withdraw(uint256 _amount) public  {
        require(_tips[msg.sender] >= _amount, "Insufficient balance");
        
        _tips[msg.sender] -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }
    
    

}