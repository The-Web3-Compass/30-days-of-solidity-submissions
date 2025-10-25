// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";

contract PremiumDepositBox is IDepositBox {
    address private _owner;
    uint256 public premiumLimit = 10 ether;

    constructor(address initialOwner) {
        _owner = initialOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    function deposit() external payable override {
        require(msg.value >= 0.1 ether, "Minimum 0.1 ETH required");
    }

    function withdraw(uint256 amount) external override onlyOwner {
        require(amount <= premiumLimit, "Exceeds premium limit");
        payable(_owner).transfer(amount);
    }

    function getBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }

    function owner() external view override returns (address) {
        return _owner;
    }
}
