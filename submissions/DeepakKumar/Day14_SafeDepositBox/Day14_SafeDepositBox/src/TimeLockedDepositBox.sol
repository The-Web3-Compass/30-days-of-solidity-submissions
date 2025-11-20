// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";

contract TimeLockedDepositBox is IDepositBox {
    address private _owner;
    uint256 public unlockTime;

    constructor(address initialOwner, uint256 lockDuration) {
        _owner = initialOwner;
        unlockTime = block.timestamp + lockDuration;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    function deposit() external payable override {}

    function withdraw(uint256 amount) external override onlyOwner {
        require(block.timestamp >= unlockTime, "Locked");
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
