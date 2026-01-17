// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DigitalPiggyBank {
    
    modifier nonReentrant() {
        require(!_locked, "Reentrancy detected");
        _locked = true;
        _;
        _locked = false;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        _balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external nonReentrant {
        uint256 userBalance = _balances[msg.sender];
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(userBalance >= amount, "Insufficient balance");

        // Update balance before transferring (Checks-Effects-Interactions pattern)
        _balances[msg.sender] = userBalance - amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function getMyBalance() external view returns (uint256) {
        return _balances[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
