// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Security Note: Reentrancy is a major vulnerability.
// We implement the Checks-Effects-Interactions pattern and a ReentrancyGuard to prevent it.

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract FortKnox is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        // Checks-Effects-Interactions Pattern
        // 1. Checks (done above)
        // 2. Effects
        balances[msg.sender] = 0;

        // 3. Interactions
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
}