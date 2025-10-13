// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBankModule {
    function balanceOf(address token, address account) external view returns (uint256);
    function transfer(address token, address to, uint256 amount) external payable returns (bool);
}

error NotOwner();
error InvalidAddress();
error TransferFailed();

contract InjectiveBankDemo {
    address public owner;
    address public bank;
    address public token;

    constructor(address _bank, address _token) {
        owner = msg.sender;
        if (_bank == address(0) || _token == address(0)) revert InvalidAddress();
        bank = _bank;
        token = _token;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function setBank(address _bank) external onlyOwner {
        if (_bank == address(0)) revert InvalidAddress();
        bank = _bank;
    }

    function setToken(address _token) external onlyOwner {
        if (_token == address(0)) revert InvalidAddress();
        token = _token;
    }

    function contractTokenBalance() external view returns (uint256) {
        return IBankModule(bank).balanceOf(token, address(this));
    }

    function sendFromContract(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert InvalidAddress();
        bool ok = IBankModule(bank).transfer{value: 0}(token, to, amount);
        if (!ok) revert TransferFailed();
    }
}