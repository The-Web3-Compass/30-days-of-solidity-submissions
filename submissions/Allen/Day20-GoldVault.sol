// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GoldVault{
    
    mapping(address => uint256) goldBalance;

    // Reentrancy lock setup
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
    This modifier is the core defense that protects our contract from reentrancy attacks.
    */
    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call blocked");
        _status = _ENTERED;
        // Solidity will replace the _ with the function code during execution.
        _;
        _status = _NOT_ENTERED;
    }

    function deposit() external payable {
        require(msg.value > 0, "Invalid amount");
        goldBalance[msg.sender] += msg.value;
    }

    /**
    if msg.sender is a smart contract, its receive() function gets triggered
    as soon as it receives ETH. And inside that receive(), 
    it calls vulnerableWithdraw() again.
    External call made before state is updated.
    Attacker re-enters while the vault is still in the middle of processing.
    ETH gets drained multiple times from a single balance.
    */
    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        goldBalance[msg.sender] = 0;
    }

    // nonReentrant:block any recursive attack attempts and
    // safely lock the vault during withdrawal.
    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // Update State Before Sending ETH
        goldBalance[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }





}