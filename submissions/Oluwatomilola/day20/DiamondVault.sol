// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DiamondVault {
    mapping(address => uint256) public diamondBalance;

    uint256 private _status;
    uint256 private _NOT_ENTERED = 1;
    uint256 private _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    } 

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call blocked ");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        diamondBalance[msg.sender] += msg.value;
    }

    function vunerableWithdraw() external {
        uint256 amount = diamondBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Eth transfer failed");
        diamondBalance[msg.sender] = 0;
    }

    function safeWithdraw() external nonReentrant {
        uint256 amount = diamondBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        diamondBalance[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }


}