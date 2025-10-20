// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

contract GoldVault {

    mapping (address => uint256) public goldBalances;
    
    // reentrancy lock setup 
    uint256 private _status;
    uint256 private constant _Not_Entered = 1;
    uint256 private constant _Entered = 2;


    constructor() {
        _status = _Not_Entered;
    }

    modifier nonReentrant() {
        require(_status != _Entered, "Reentrant call blocked");
        _status = _Entered;
        _;
        _status = _Not_Entered;
    }


    function deposit() external payable {
        require (msg.value > 0, "Deposit must bw more than zero");
        goldBalances[msg.sender] += msg.value;
    }

    function vulnerableWithdraw() external {
        uint256 amount = goldBalances[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Eth transfer failed");
        goldBalances[msg.sender] = 0;
    }

    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalances[msg.sender];
        require(amount > 0, "Nothing to witdraw");

        goldBalances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require (sent, "Eth transfer failed");
    }
}