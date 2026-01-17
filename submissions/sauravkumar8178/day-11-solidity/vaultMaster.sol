// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";

contract VaultMaster is Ownable {
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    constructor() {
        _status = _NOT_ENTERED;
    }
\
    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "VaultMaster: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    receive() external payable {
        require(msg.value > 0, "VaultMaster: no ETH sent");
        emit Deposited(msg.sender, msg.value);
    }
.
    fallback() external payable {
        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    function deposit() external payable {
        require(msg.value > 0, "VaultMaster: no ETH sent");
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount, address payable to) external onlyOwner nonReentrant {
        require(to != address(0), "VaultMaster: zero address");
        require(address(this).balance >= amount, "VaultMaster: insufficient balance");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "VaultMaster: transfer failed");

        emit Withdrawn(to, amount);
    }

    function withdrawAll(address payable to) external onlyOwner nonReentrant {
        require(to != address(0), "VaultMaster: zero address");
        uint256 bal = address(this).balance;
        require(bal > 0, "VaultMaster: empty balance");

        (bool ok, ) = to.call{value: bal}("");
        require(ok, "VaultMaster: transfer failed");

        emit Withdrawn(to, bal);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
